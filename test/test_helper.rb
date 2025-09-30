require 'minitest/hooks/test'

# Avoid coverage report when running a single test
unless ARGV.include?('-n')
  require 'simplecov'
  puts 'Starting coverage...'
  SimpleCov.start 'rails' do
    nocov_token 'nocov'
    merge_timeout 3600
    command_name "Tests #{rand(100000)}"
    add_filter do |file|
      (!file.filename.match(/\/app\/controllers\/[^\/]+\.rb$/).nil? && file.filename.match(/application_controller\.rb$/).nil?) ||
      !file.filename.match(/\/app\/controllers\/concerns\/[^\/]+_doc\.rb$/).nil? ||
      !file.filename.match(/\/lib\/sample_data\.rb$/).nil? ||
      !file.filename.match(/\/lib\/tasks\//).nil? ||
      !file.filename.match(/\/app\/graph\/types\/mutation_type\.rb$/).nil? ||
      !file.filename.match(/\/app\/graphql\/types\/mutation_type\.rb$/).nil? ||
      !file.filename.match(/\/lib\/check_statistics\.rb$/).nil?
    end
    coverage_dir 'coverage'
  end
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'sample_data'
require 'parallel_tests/test/runtime_logger'
require 'sidekiq/testing'
require 'minitest/retry'
require 'pact/consumer/minitest'
require 'mocha/minitest'
require 'csv'
require 'smooch_bot_test_helper'

Dir[Rails.root.join("test/support/**/*.rb")].each {|f| require f}

Minitest::Retry.use!(retry_count: ENV['TEST_RETRY_COUNT'].to_i || 0)
TestDatabaseHelper.setup_database_partitions!

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class << Concurrent::Future
  alias_method :original_execute, :execute
  def execute(args = {}, &block)
    if Rails.env == 'test'
      yield
    else
      original_execute(args, &block)
    end
  end
end

class Api::V1::TestController < Api::V1::BaseApiController
  before_action :verify_payload!, only: [:notify]
  skip_before_action :authenticate_from_token!, only: [:notify]

  def test
    @p = get_params
    render_success
  end

  def options
    render text: ''
  end

  def notify
    render_success 'success', @payload
  end
end

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
  end
end

class ActiveSupport::TestCase
  include SampleData
  include Minitest::Hooks
  include ActiveSupport::Testing::TimeHelpers

  def json_response
    JSON.parse(@response.body)
  end

  def stub_configs(configs, must_unstub = true)
    CONFIG.stubs(:[]).returns(nil)
    CONFIG.stubs(:has_key?).returns(false)
    CONFIG.each do |k, v|
      CONFIG.stubs(:[]).with(k).returns(v)
      CONFIG.stubs(:has_key?).with(k).returns(true)
    end
    configs.each do |k, v|
      CONFIG.stubs(:[]).with(k).returns(v)
      CONFIG.stubs(:has_key?).with(k).returns(true)
    end
    yield if block_given?
    CONFIG.unstub(:[]) if must_unstub
    CONFIG.unstub(:has_key?) if must_unstub
  end

  def setup_elasticsearch
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    User.unstub(:current)
    Team.current = nil
    User.current = nil
    MediaSearch.delete_index
    MediaSearch.create_index
    RequestStore.store[:disable_es_callbacks] = false
    create_verification_status_stuff
    sleep 2
  end

  def with_current_user_and_team(user = nil, team = nil)
    user = user.nil? ? nil : user.reload
    if team.nil?
      User.current = user
      Team.current = nil
    else
      Team.stubs(:current).returns(team)
      User.stubs(:current).returns(user)
    end
    begin
      yield if block_given?
    rescue Exception => e
      raise e
    ensure
      if team.nil?
        User.current = nil
        Team.current = nil
      else
        User.unstub(:current)
        Team.unstub(:current)
      end
    end
  end

  # This will run before all tests

  def before_all
    super
    @start = Time.now

    create_metadata_stuff
    @exporter = Check::OpenTelemetryTestConfig.current_exporter
    # URL mocked by pender-client
    @url = 'https://www.youtube.com/user/MeedanTube'
  end

  # This will run before any test

  def setup
    Sidekiq::Testing.fake!
    [Account, Media, ProjectMedia, User, Source, Annotation, Team, TeamUser, Relationship, TiplineResource, TiplineRequest].each{ |klass| klass.delete_all }

    # Some of our non-GraphQL tests rely on behavior that this requires. As a result,
    # we'll keep it around for now and just recreate any needed dynamic annotation data
    # in the setup of our controller tests. But, ideally we'd not do this since it's just
    # extra work.
    DynamicAnnotation::AnnotationType.where.not(annotation_type: 'metadata').delete_all
    DynamicAnnotation::FieldType.where.not(field_type: 'json').delete_all
    DynamicAnnotation::FieldInstance.where.not(name: 'metadata_value').delete_all

    ENV['BOOTSNAP_CACHE_DIR'] = "#{Rails.root}/tmp/cache#{ENV['TEST_ENV_NUMBER']}"
    FileUtils.rm_rf(File.join(Rails.root, 'tmp', "cache<%= ENV['TEST_ENV_NUMBER'] %>", '*'))
    Rails.application.reload_routes!
    I18n.locale = :en
    Sidekiq::Worker.clear_all
    Rails.cache.clear
    RequestStore.unstub(:[])
    ApiKey.current = Team.current = User.current = nil
    Team.unstub(:current)
    User.unstub(:current)
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'http://localhost' } }).to_return(body: '{"type":"media","data":{"url":"http://localhost","type":"item","foo":"1"}}')
    WebMock.stub_request(:get, /#{CheckConfig.get('narcissus_url')}/).to_return(body: '{"url":"http://screenshot/test/test.png"}')
    WebMock.stub_request(:get, /api\.smooch\.io/)
    RequestStore.store[:skip_cached_field_update] = true

    # Set up stubs on per-test basis so that we don't accidentally
    # create a shared state for stubbing and unstubbing
    Pusher::Client.any_instance.stubs(:trigger)
    Pusher::Client.any_instance.stubs(:post)
    ProjectMedia.any_instance.stubs(:clear_caches).returns(nil)
  end

  # This will run after any test

  def teardown
    WebMock.reset!
    WebMock.allow_net_connect!
    Time.unstub(:now)
    Rails.unstub(:env)
    RequestStore.unstub(:[])
    User.current = nil
    RequestStore.clear!
    CONFIG.unstub(:[])
  end

  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_enabled_for_request = PaperTrail.request.enabled?
    PaperTrail.enabled = true
    PaperTrail.request.enabled = true
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
      PaperTrail.request.enabled = was_enabled_for_request
    end
  end

  def valid_flags_data(random = true)
    keys = ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam']
    flags = {}
    keys.each do |key|
      flags[key] = (random ? random_number(4) : 1)
    end
    { flags: flags }
  end

  def assert_queries(num = 1, operator = '=', test = true, &block)
    old = ApplicationRecord.connection.query_cache_enabled
    ApplicationRecord.connection.enable_query_cache!
    queries  = []
    callback = lambda { |name, start, finish, id, payload|
      queries << payload[:sql] if payload[:sql] =~ /^SELECT|UPDATE|INSERT/ and !payload[:cached]
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  ensure
    ApplicationRecord.connection.disable_query_cache! unless old
    debug = "Total of #{queries.size} Queries:\n#{queries.join("\n")}"
    msg = "#{queries.size} expected to be #{operator} #{num}. " + debug
    if test
      if operator == '='
        assert_equal num, queries.size, msg
      elsif operator == '<'
        assert queries.size < num, msg
      elsif operator == '<='
        assert queries.size <= num, msg
      elsif operator == '>='
        assert queries.size >= num, msg
      elsif operator == '>'
        assert queries.size > num, msg
      end
    else
      puts debug
    end
  end

  def authenticate_with_token(api_key = nil)
    unless @request.nil?
      header = CheckConfig.get('authorization_header', 'X-Token')
      api_key ||= create_api_key
      @request.headers.merge!({ header => api_key.access_token })
    end
  end

  def authenticate_with_user_token(token = nil)
    unless @request.nil?
      header = CheckConfig.get('authorization_header', 'X-Token')
      token ||= create_omniauth_user.token
      @request.headers.merge!({ header => token })
    end
  end

  def authenticate_with_user(user = nil)
    user ||= create_user
    create_team_user(user: user, team: @team, role: 'admin') if user.current_team.nil?
    @request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_in user
  end

  def assert_task_response_attribution
    u1 = create_user name: 'User 1'
    u2 = create_user name: 'User 2'
    u3 = create_user name: 'User 3'
    t = create_team
    create_team_user user: u1, team: t, role: 'admin'
    create_team_user user: u2, team: t, role: 'admin'
    create_team_user user: u3, team: t, role: 'admin'
    pm = create_project_media team: t

    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'task_response_free_text').first || create_annotation_type(annotation_type: 'task_response_free_text', label: 'Task')
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_task', label: 'Note', field_type_object: ft1
    tk = create_task annotated: pm
    tk.disable_es_callbacks = true
    tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Test' }.to_json }.to_json
    tk.save!

    a = Dynamic.where(annotation_type: 'task_response_free_text').last

    assert_equal '', a.attribution

    with_current_user_and_team(u1, t) do
      a = Dynamic.find(a.id)
      a.set_fields = { response_task: 'Test 1' }.to_json
      a.save!
      assert_equal [u1.id].join(','), a.reload.attribution
    end

    with_current_user_and_team(u2, t) do
      a = Dynamic.find(a.id)
      a.set_fields = { response_task: 'Test 2' }.to_json
      a.save!
      assert_equal [u1.id, u2.id].join(','), a.reload.attribution
    end

    with_current_user_and_team(u2, t) do
      a = Dynamic.find(a.id)
      a.set_attribution = u1.id.to_s
      a.set_fields = { response_task: 'Test 3' }.to_json
      a.save!
      assert_equal [u1.id].join(','), a.reload.attribution
    end

    with_current_user_and_team(u3, t) do
      a = Dynamic.find(a.id)
      a.set_fields = { response_task: 'Test 4' }.to_json
      a.save!
      assert_equal [u1.id, u3.id].join(','), a.reload.attribution
    end

    [t, pm]
  end

  # CRUD helpers for GraphQL types

  def assert_graphql_create(type, request_params = {}, response_fields = ['id'])
    authenticate_with_user

    klass = type.camelize

    input = '{'
    request_params.merge({ clientMutationId: '1' }).each do |key, value|
      input += "#{key}: #{value.to_json}, "
    end
    input.gsub!(/, $/, '}')

    query = "mutation create { create#{klass}(input: #{input}) { #{type} { #{response_fields.join(',')} } } }"

    assert_difference "#{klass}.count" do
      post :create, params: { query: query }
      assert_response :success
      yield if block_given?
    end

    document_graphql_query('create', type, query, @response.body)
  end

  def assert_graphql_update(type, attr, from, to)
    obj = send("create_#{type}", { team: @team }.merge({ attr => from }))
    user = obj.is_a?(User) ? obj : create_user
    create_team_user(user: user, team: obj, role: 'admin') if obj.is_a?(Team)
    authenticate_with_user(user)

    klass = obj.class.to_s
    assert_equal from, obj.send(attr)
    id = obj.graphql_id
    input = '{ clientMutationId: "1", id: "' + id.to_s + '", ' + attr.to_s + ': ' + to.to_json + ' }'
    query = "mutation update { update#{klass}(input: #{input}) { #{type} { #{attr} } } }"
    post :create, params: { query: query }
    yield if block_given?
    assert_response :success
    assert_equal to, obj.reload.send(attr)
    document_graphql_query('update', type, query, @response.body)
  end

  def assert_graphql_destroy(type)
    authenticate_with_user
    obj = type === 'team' ? @team : send("create_#{type}", { team: @team })
    klass = obj.class_name
    id = obj.graphql_id
    query = "mutation destroy { destroy#{klass}(input: { clientMutationId: \"1\", id: \"#{id}\" }) { deletedId } }"
    assert_difference "#{klass}.count", -1 do
      post :create, params: { query: query }
      yield if block_given?
    end
    assert_response :success
    document_graphql_query('destroy', type, query, @response.body)
  end

  def assert_graphql_get_by_id(type, field, value)
    authenticate_with_user
    obj = send("create_#{type}", { field.to_sym => value, team: @team })
    query = "query GetById { #{type}(id: \"#{obj.id}\") { #{field} } }"
    post :create, params: { query: query }
    assert_response :success
    document_graphql_query('get_by_id', type, query, @response.body)
    data = JSON.parse(@response.body)['data'][type]
    assert_equal value, data[field]
  end

  def create_smooch_bot
    settings = SmoochBotTestHelper::Settings.initial
    create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: settings, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
  end

  def setup_smooch_bot(menu = false, extra_settings = {})
    DynamicAnnotation::AnnotationType.delete_all
    DynamicAnnotation::FieldInstance.delete_all
    DynamicAnnotation::FieldType.delete_all
    DynamicAnnotation::Field.delete_all
    create_verification_status_stuff
    create_annotation_type_and_fields('Smooch Response', { 'Data' => ['JSON', true] })
    create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
    Sidekiq::Testing.inline!
    @app_id = random_string
    @msg_id = random_string
    messages = (1..20).to_a.collect{ |_i| OpenStruct.new({ message: OpenStruct.new({ id: random_string }) }) }
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).returns(*messages)
    @team = create_team
    @bid = random_string
    ApiKey.delete_all
    BotUser.delete_all
    @resource_uuid = random_string

    @bot = create_smooch_bot
    @settings = SmoochBotTestHelper::Settings.basic(@app_id, @team.id)
    @pm_for_menu_option = create_project_media(team: @team)

    if menu
      @team.set_languages = ['en', 'pt']
      @team.save!

      smooch_menu = SmoochBotTestHelper::Menu.new(@pm_for_menu_option.id, @resource_uuid)
      smooch_menu.add_default_language(@settings)
      smooch_menu.add_second_language(@settings)
    end
    @installation = create_team_bot_installation user_id: @bot.id, settings: @settings.merge(extra_settings), team_id: @team.id
    @installation.set_smooch_version = 'v1' ; @installation.save!
    create_team_bot_installation user_id: @bot.id, settings: {}, team_id: create_team.id
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    @media_url = 'https://smooch.com/image/test.jpeg'
    @media_url_2 = 'https://smooch.com/image/test2.jpeg'
    @media_url_3 = 'https://smooch.com/image/large-image.jpeg'
    @video_url = 'https://smooch.com/video/test.mp4'
    @video_url_2 = 'https://smooch.com/video/fake-video.mp4'
    @audio_url = 'https://smooch.com/audio/test.mp3'
    @audio_url_2 = 'https://smooch.com/audio/fake-audio.mp3'
    WebMock.stub_request(:get, @media_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    WebMock.stub_request(:head, @media_url).to_return(status: 200, headers: {'content-type' => 'image/jpeg'})
    WebMock.stub_request(:get, @media_url_2).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails2.png')))
    WebMock.stub_request(:head, @media_url_2).to_return(status: 200, headers: {'content-type' => 'image/jpeg'})
    WebMock.stub_request(:get, @media_url_3).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'large-image.jpg')))
    WebMock.stub_request(:head, @media_url_3).to_return(status: 200, headers: {'content-type' => 'image/jpeg'})
    WebMock.stub_request(:get, @video_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')))
    WebMock.stub_request(:head, @video_url).to_return(status: 200, headers: {'content-type' => 'video/mp4'})
    WebMock.stub_request(:get, @video_url_2).to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:head, @video_url_2).to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:get, @audio_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
    WebMock.stub_request(:head, @audio_url).to_return(status: 200, headers: {'content-type' => 'audio/mpeg'})
    WebMock.stub_request(:get, @audio_url_2).to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:head, @audio_url_2).to_return(status: 200, body: '', headers: {})
    @link_url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: @link_url } }).to_return({ body: '{"type":"media","data":{"url":"' + @link_url + '","type":"item"}}' })
    @link_url_2 = 'https://' + random_string + '.com'
    WebMock.stub_request(:get, pender_url).with({ query: { url: @link_url_2 } }).to_return({ body: '{"type":"media","data":{"url":"' + @link_url_2 + '","type":"item"}}' })
    Bot::Smooch.stubs(:get_language).returns('en')
    create_alegre_bot
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://www.instagram.com/p/Bu3enV8Fjcy' } }).to_return({ body: '{"type":"media","data":{"url":"https://www.instagram.com/p/Bu3enV8Fjcy","type":"item"}}' })
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://www.instagram.com/p/Bu3enV8Fjcy/?utm_source=ig_web_copy_link' } }).to_return({ body: '{"type":"media","data":{"url":"https://www.instagram.com/p/Bu3enV8Fjcy","type":"item"}}' })
    WebMock.stub_request(:get, /check_message_tos/).to_return({ body: '<h1>Check Message Terms of Service</h1><p class="meta">Last modified: August 7, 2019</p>' })
    Bot::Smooch.stubs(:save_user_information).returns(nil)
    create_tipline_newsletter(
      send_every: ['monday'],
      time: Time.parse('10:00'),
      timezone: 'BRT',
      introduction: 'Test',
      content_type: 'rss',
      rss_feed_url: 'http://test.com/feed.rss',
      number_of_articles: 3,
      team: @team,
      language: 'en'
    )
    @resource = create_tipline_resource(
      uuid: @resource_uuid,
      title: 'Latest articles',
      introduction: 'Take a look at our latest published articles.',
      rss_feed_url: 'http://test.com/feed.rss',
      number_of_articles: 3,
      team: @team,
      language: 'en'
    )
  end

  def send_message_to_smooch_bot(message = random_string, user = random_string, extra = {})
    messages = [
      {
        '_id': random_string,
        authorId: user,
        type: 'text',
        text: message,
        source: { type: "whatsapp" },
        language: 'en',
      }.merge(extra)
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': user,
        'conversationStarted': true
      }
    }.to_json
    Bot::Smooch.run(payload)
  end

  def publish_report(pm = nil, data = {}, report = nil, option_data = {})
    pm ||= create_project_media
    r = report || create_report(pm, data, 'save', option_data)
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'published' }.to_json
    r.action = 'publish'
    r.save!
    r
  end

  def create_report(pm, data = {}, action = 'save', option_data = {})
    create_report_design_annotation_type if DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last.nil?
    r = create_dynamic_annotation annotation_type: 'report_design', annotated: pm
    default_data = {
      state: 'paused',
      options: {
        language: 'en',
        status_label: random_string,
        use_introduction: true,
        introduction: 'Regarding {{query_message}} on {{query_date}}, it is {{status}}.',
        use_visual_card: true,
        description: random_string,
        headline: random_string,
        image: '',
        theme_color: '#FF0000',
        url: random_url,
        use_text_message: true,
        title: random_string,
        text: random_string,
        published_article_url: random_url,
        use_disclaimer: true,
        disclaimer: random_string
      }.merge(option_data)
    }
    r.set_fields = default_data.merge(data).to_json
    r.action = action
    r.save!
    r
  end

  # Document GraphQL queries in Markdown format
  def document_graphql_query(action, type, query, response)
    if ENV['DOCUMENT']
      file = File.join(Rails.root, 'doc', 'graphql', "#{type}.md")
      unless File.exist?(file)
        log = File.open(file, 'w+')
        log.puts('')
        log.puts("## #{type.split('_').map(&:capitalize).join(' ')}")
        log.puts('')
        log.close
      end
      log = File.open(file, 'a+')
      log.puts <<-eos
### __#{action.split('_').map(&:capitalize).join(' ')} #{type.split('_').map(&:capitalize).join(' ')}__

#### __Query__

```graphql
#{query}
```

#### __Result__

```json
#{JSON.pretty_generate(JSON.parse(response))}
```

      eos
      log.close
    end
  end

  def media_filename(filename, extension = true)
    File.open(File.join(Rails.root, 'test', 'data', filename)) do |f|
      return Media.filename(f, extension)
    end
  end
end
