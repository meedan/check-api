require 'simplecov'
require 'minitest/hooks/test'

SimpleCov.start 'rails' do
  nocov_token 'nocov'
  merge_timeout 3600
  command_name "Tests #{rand(100000)}"
  add_filter do |file|
    (!file.filename.match(/\/app\/controllers\/[^\/]+\.rb$/).nil? && file.filename.match(/application_controller\.rb$/).nil?) ||
    !file.filename.match(/\/app\/controllers\/concerns\/[^\/]+_doc\.rb$/).nil? ||
    !file.filename.match(/\/lib\/sample_data\.rb$/).nil?
  end
  coverage_dir 'coverage'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'mocha/test_unit'
require 'sample_data'
require 'parallel_tests/test/runtime_logger'
require 'sidekiq/testing'
require 'minitest/retry'
Minitest::Retry.use!

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class Api::V1::TestController < Api::V1::BaseApiController
  before_filter :verify_payload!, only: [:notify]
  skip_before_filter :authenticate_from_token!, only: [:notify]

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

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  include SampleData
  include Minitest::Hooks

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
    Rails.stubs(:env).returns('development')
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
    create_metadata_stuff
    ApolloTracing.stubs(:start_proxy)
    Pusher::Client.any_instance.stubs(:trigger)
    Pusher::Client.any_instance.stubs(:post)
    ProjectMedia.any_instance.stubs(:clear_caches).returns(nil)
    # URL mocked by pender-client
    @url = 'https://www.youtube.com/user/MeedanTube'
  end

  # This will run before any test

  def setup
    [Account, Media, ProjectMedia, User, Source, Annotation, Team, TeamUser, Relationship].each{ |klass| klass.delete_all }
    DynamicAnnotation::AnnotationType.where.not(annotation_type: 'metadata').delete_all
    DynamicAnnotation::FieldType.where.not(field_type: 'json').delete_all
    DynamicAnnotation::FieldInstance.where.not(name: 'metadata_value').delete_all
    FileUtils.rm_rf(File.join(Rails.root, 'tmp', "cache<%= ENV['TEST_ENV_NUMBER'] %>", '*'))
    Rails.application.reload_routes!
    I18n.locale = :en
    Sidekiq::Worker.clear_all
    Rails.cache.clear
    RequestStore.unstub(:[])
    ApiKey.current = Team.current = User.current = nil
    Team.unstub(:current)
    User.unstub(:current)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'http://localhost' } }).to_return(body: '{"type":"media","data":{"url":"http://localhost","type":"item","foo":"1"}}')
    WebMock.stub_request(:get, /#{CONFIG['narcissus_url']}/).to_return(body: '{"url":"http://screenshot/test/test.png"}')
    WebMock.stub_request(:get, /api\.smooch\.io/)
    RequestStore.store[:skip_cached_field_update] = true
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
    old = ActiveRecord::Base.connection.query_cache_enabled
    ActiveRecord::Base.connection.enable_query_cache!
    queries  = []
    callback = lambda { |name, start, finish, id, payload|
      queries << payload[:sql] if payload[:sql] =~ /^SELECT|UPDATE|INSERT/ and payload[:name] != 'CACHE'
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  ensure
    ActiveRecord::Base.connection.disable_query_cache! unless old
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
      header = CONFIG['authorization_header'] || 'X-Token'
      api_key ||= create_api_key
      @request.headers.merge!({ header => api_key.access_token })
    end
  end

  def authenticate_with_user_token(token = nil)
    unless @request.nil?
      header = CONFIG['authorization_header'] || 'X-Token'
      token ||= create_omniauth_user.token
      @request.headers.merge!({ header => token })
    end
  end

  def authenticate_with_user(user = nil)
    user ||= create_user
    create_team_user(user: user, team: @team, role: 'owner') if user.current_team.nil?
    @request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_in user
  end

  def assert_task_response_attribution
    u1 = create_user name: 'User 1'
    u2 = create_user name: 'User 2'
    u3 = create_user name: 'User 3'
    t = create_team
    create_team_user user: u1, team: t, role: 'owner'
    create_team_user user: u2, team: t, role: 'owner'
    create_team_user user: u3, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p

    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
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

    [t, p, pm]
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
      post :create, query: query
      assert_response :success
      yield if block_given?
    end

    document_graphql_query('create', type, query, @response.body)
  end

  def assert_graphql_read(type, field = 'id')
    klass = (type == 'version') ? PaperTrail::Version : type.camelize.constantize
    klass.delete_all
    u = create_user
    x1 = send("create_#{type}", { team: @team })
    x2 = send("create_#{type}", { team: @team })
    user = type == 'user' ? x1 : u
    authenticate_with_user(user)
    query = "query read { root { #{type.pluralize} { edges { node { #{field} } } } } }"
    post :create, query: query
    yield if block_given?
    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    n = [Comment, Tag, Task].include?(klass) ? klass.where(annotation_type: type.to_s).count : klass.count
    assert_equal n, edges.size
    edges = edges.collect{ |e| e['node'][field].to_s }
    assert edges.include?(x1.send(field).to_s)
    assert edges.include?(x2.send(field).to_s)
    assert_response :success
    document_graphql_query('read', type, query, @response.body)
  end

  def assert_graphql_update(type, attr, from, to)
    obj = send("create_#{type}", { team: @team }.merge({ attr => from }))
    user = obj.is_a?(User) ? obj : create_user
    create_team_user(user: user, team: obj, role: 'owner') if obj.is_a?(Team)
    authenticate_with_user(user)

    klass = obj.class.to_s
    assert_equal from, obj.send(attr)
    id = obj.graphql_id
    input = '{ clientMutationId: "1", id: "' + id.to_s + '", ' + attr.to_s + ': ' + to.to_json + ' }'
    query = "mutation update { update#{klass}(input: #{input}) { #{type} { #{attr} } } }"
    post :create, query: query
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
      post :create, query: query
      yield if block_given?
    end
    assert_response :success
    document_graphql_query('destroy', type, query, @response.body)
  end

  def assert_graphql_read_object(type, fields = {})
    type.camelize.constantize.delete_all

    x1 = nil
    x2 = nil
    if type === 'annotation'
      pm = create_project_media
      Annotation.delete_all
      x1 = create_comment(annotated: pm).reload
      x2 = create_comment(annotated: pm).reload
      Annotation.where("annotation_type != 'comment'").delete_all
    else
      x1 = send("create_#{type}").reload
      x2 = send("create_#{type}").reload
    end

    node = '{ '
    fields.each do |name, key|
      node += "#{name} { #{key} }, "
    end
    node.gsub!(/, $/, ' }')

    query = "query read { root { #{type.pluralize} { edges { node #{node} } } } }"

    type === 'user' ? authenticate_with_user(x1) : authenticate_with_user

    post :create, query: query

    yield if block_given?

    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    assert_equal type.camelize.constantize.count, edges.size

    objs = [x1, x2]

    fields.each do |name, key|
      equal = false
      edges.each do |edge|
        objs.each do |obj|
          equal = (obj.send(name).send(key) == edge['node'][name][key]) unless equal
        end
      end
      assert equal
    end

    assert_response :success
    document_graphql_query('read_object', type, query, @response.body)
  end

  def assert_graphql_read_collection(type, fields = {}, order = 'ASC')
    type.camelize.constantize.delete_all

    obj = send("create_#{type}")

    node = '{ '
    fields.each do |name, key|
      if name === 'medias' && obj.is_a?(Source)
        m = create_valid_media(account: create_valid_account(source: obj))
        p = create_project team: @team
        create_project_media media: m, project: p
      elsif name === 'collaborators'
        obj.add_annotation create_comment(annotator: create_user)
      elsif name === 'annotations' || name === 'comments'
        if obj.annotations.empty?
          c = create_comment annotated: nil
          obj.is_a?(User) ? create_comment(annotator: obj, annotated: nil) : obj.add_annotation(c)
        end
      elsif name === 'tags'
        create_tag annotated: obj
      elsif name === 'tasks'
        create_task annotated: obj
      elsif name === 'join_requests'
        obj.team_users << create_team_user(team: obj, role: 'contributor', status: 'requested')
      else
        RequestStore.store[:disable_es_callbacks] = true
        obj.disable_es_callbacks = true if obj.respond_to?(:disable_es_callbacks)
        obj.send(name).send('<<', [send("create_#{name.singularize}")])
        obj.save!
        RequestStore.store[:disable_es_callbacks] = false
      end
      obj = obj.reload
      node += "#{name} { edges { node { #{key} } } }, "
    end
    node.gsub!(/, $/, ' }')

    query = "query read { root { #{type.pluralize} { edges { node #{node} } } } }"
    type === 'user' ? authenticate_with_user(obj) : authenticate_with_user

    post :create, query: query

    yield if block_given?

    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']

    fields.each do |name, key|
      next if !obj.respond_to?(name)
      equal = false
      edges.each do |edge|
        if edge['node'][name]['edges'].size > 0 && !equal
          equal = (obj.send(name).first.send(key) == edge['node'][name]['edges'][0]['node'][key])
          equal = (obj.send(name).last.send(key) == edge['node'][name]['edges'][0]['node'][key]) unless equal
        end
      end
      assert equal
    end

    assert_response :success
    document_graphql_query('read_collection', type, query, @response.body)
  end

  def assert_graphql_get_by_id(type, field, value)
    authenticate_with_user
    obj = send("create_#{type}", { field.to_sym => value, team: @team })
    query = "query GetById { #{type}(id: \"#{obj.id}\") { #{field} } }"
    post :create, query: query
    assert_response :success
    document_graphql_query('get_by_id', type, query, @response.body)
    data = JSON.parse(@response.body)['data'][type]
    assert_equal value, data[field]
  end

  def setup_smooch_bot(menu = false)
    DynamicAnnotation::AnnotationType.delete_all
    DynamicAnnotation::FieldInstance.delete_all
    DynamicAnnotation::FieldType.delete_all
    DynamicAnnotation::Field.delete_all
    create_verification_status_stuff
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    create_annotation_type_and_fields('Smooch Response', { 'Data' => ['JSON', true] })
    create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}|#{CONFIG['storage']['endpoint']}/
    Sidekiq::Testing.inline!
    @app_id = random_string
    @msg_id = random_string
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).returns(OpenStruct.new({ message: OpenStruct.new({ id: @msg_id }) }))
    @team = create_team
    @project = create_project team_id: @team.id
    @bid = random_string
    BotUser.delete_all
    settings = [
      { name: 'smooch_app_id', label: 'Smooch App ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_key_id', label: 'Smooch Secret Key: Key ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_secret', label: 'Smooch Secret Key: Secret', type: 'string', default: '' },
      { name: 'smooch_webhook_secret', label: 'Smooch Webhook Secret', type: 'string', default: '' },
      { name: 'smooch_template_namespace', label: 'Smooch Template Namespace', type: 'string', default: '' },
      { name: 'smooch_bot_id', label: 'Smooch Bot ID', type: 'string', default: '' },
      { name: 'smooch_project_id', label: 'Check Project ID', type: 'number', default: '' },
      { name: 'smooch_window_duration', label: 'Window Duration (in hours - after this time since the last message from the user, the user will be notified... enter 0 to disable)', type: 'number', default: 20 },
      { name: 'smooch_localize_messages', label: 'Localize custom messages', type: 'boolean', default: false },
    ]
    {
      'smooch_bot_result' => 'Message sent with the verification results (placeholders: %{status} (final status of the report) and %{url} (public URL to verification results))',
      'smooch_bot_result_changed' => 'Message sent with the new verification results when a final status of an item changes (placeholders: %{previous_status} (previous final status of the report), %{status} (new final status of the report) and %{url} (public URL to verification results))',
      'smooch_bot_ask_for_confirmation' => 'Message that asks the user to confirm the request to verify an item... should mention that the user needs to sent "1" to confirm',
      'smooch_bot_message_confirmed' => 'Message that confirms to the user that the request is in the queue to be verified',
      'smooch_bot_message_type_unsupported' => 'Message that informs the user that the type of message is not supported (for example, audio and video)',
      'smooch_bot_message_unconfirmed' => 'Message sent when the user does not send "1" to confirm a request',
      'smooch_bot_not_final' => 'Message when an item was wrongly marked as final, but that status is reverted (placeholder: %{status} (previous final status))',
      'smooch_bot_meme' => 'Message sent along with a meme (placeholder: %{url} (public URL to verification results))',
    }.each do |name, label|
      settings << { name: "smooch_message_#{name}", label: label, type: 'string', default: '' }
    end
    settings << { name: 'smooch_message_smooch_bot_greetings', label: 'First message that is sent to the user as an introduction about the service', type: 'string', default: '' }
    {
      'main': 'Main menu',
      'secondary': 'Secondary menu',
      'query': 'User query'
    }.each do |state, label|
      settings << {
        'name': "smooch_state_#{state}",
        'label': label,
        'type': 'object',
        'default': {},
        'properties': {
          'smooch_menu_message': {
            'type': 'string',
            'title': 'Message',
            'default': ''
          },
          'smooch_menu_options': {
            'title': 'Menu options',
            'type': 'array',
            'default': [],
            'items': {
              'title': 'Option',
              'type': 'object',
              'properties': {
                'smooch_menu_option_keyword': {
                  'title': 'If',
                  'type': 'string',
                  'default': ''
                },
                'smooch_menu_option_value': {
                  'title': 'Then',
                  'type': 'string',
                  'enum': [
                    { 'key': 'main_state', 'value': 'Main menu' },
                    { 'key': 'secondary_state', 'value': 'Secondary menu' },
                    { 'key': 'query_state', 'value': 'User query' },
                    { 'key': 'resource', 'value': 'Resource' }
                  ],
                  'default': ''
                },
                'smooch_menu_project_media_id': {
                  'title': 'Project Media ID',
                  'type': ['string', 'integer'],
                  'default': '',
                },
              }
            }
          }
        }
      }
    end
    settings << { name: 'smooch_message_smooch_bot_option_not_available', label: 'Option not available', type: 'string', default: '' }
    WebMock.stub_request(:post, 'https://www.transifex.com/api/2/project/check-2/resources').to_return(status: 200, body: 'ok', headers: {})
    WebMock.stub_request(:get, 'https://www.transifex.com/api/2/project/check-2/resource/api/translation/en').to_return(status: 200, body: { 'content' => { 'en' => {} }.to_yaml }.to_json, headers: {})
    WebMock.stub_request(:put, /^https:\/\/www\.transifex\.com\/api\/2\/project\/check-2\/resource\/api-custom-messages-/).to_return(status: 200, body: { i18n_type: 'YML', 'content' => { 'en' => {} }.to_yaml }.to_json)
    WebMock.stub_request(:get, /^https:\/\/www\.transifex\.com\/api\/2\/project\/check-2\/resource\/api-custom-messages-/).to_return(status: 200, body: { i18n_type: 'YML', 'content' => { 'en' => {} }.to_yaml }.to_json)
    WebMock.stub_request(:delete, /^https:\/\/www\.transifex\.com\/api\/2\/project\/check-2\/resource\/api-custom-messages-/).to_return(status: 200, body: 'ok')
    @bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: settings, set_events: [], set_request_url: "#{CONFIG['checkdesk_base_url_private']}/api/bots/smooch"
    @settings = {
      'smooch_project_id' => @project.id,
      'smooch_bot_id' => @bid,
      'smooch_webhook_secret' => 'test',
      'smooch_app_id' => @app_id,
      'smooch_secret_key_key_id' => random_string,
      'smooch_secret_key_secret' => random_string,
      'smooch_template_namespace' => random_string,
      'smooch_window_duration' => 10,
      'smooch_localize_messages' => true,
      'team_id' => @team.id
    }
    if menu
      @settings.merge!({
        'smooch_state_main' => {
          'smooch_menu_message' => 'Hello, welcome! Press 1 to go to secondary menu.',
          'smooch_menu_options' => [{
            'smooch_menu_option_keyword' => '1 ,one',
            'smooch_menu_option_value' => 'secondary_state',
            'smooch_menu_project_media_id' => ''
          }]
        },
        'smooch_state_secondary' => {
          'smooch_menu_message' => 'Now press 1 to see a project media or 2 to go to the query menu',
          'smooch_menu_options' => [
            {
              'smooch_menu_option_keyword' => ' 1, one',
              'smooch_menu_option_value' => 'resource',
              'smooch_menu_project_media_id' => create_project_media(project: @project).id
            },
            {
              'smooch_menu_option_keyword' => '2, two ',
              'smooch_menu_option_value' => 'query_state',
              'smooch_menu_project_media_id' => ''
            }
          ]
        },
        'smooch_state_query' => {
          'smooch_menu_message' => 'Enter your query or send 0 to go back to the main menu',
          'smooch_menu_options' => [
            {
              'smooch_menu_option_keyword' => '0,zero',
              'smooch_menu_option_value' => 'main_state',
              'smooch_menu_project_media_id' => ''
            }
          ]
        }
      })
    end
    @installation = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: @team.id
    create_team_bot_installation user_id: @bot.id, settings: {}, team_id: create_team.id
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    @media_url = 'https://smooch.com/image/test.jpeg'
    @media_url_2 = 'https://smooch.com/image/test2.jpeg'
    @media_url_3 = 'https://smooch.com/image/large-image.jpeg'
    @video_url = 'https://smooch.com/video/test.mp4'
    @video_ur_2 = 'https://smooch.com/video/fake-video.mp4'
    WebMock.stub_request(:get, 'https://smooch.com/image/test.jpeg').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    WebMock.stub_request(:get, 'https://smooch.com/image/test2.jpeg').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails2.png')))
    WebMock.stub_request(:get, 'https://smooch.com/image/large-image.jpeg').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'large-image.jpg')))
    WebMock.stub_request(:get, 'https://smooch.com/video/test.mp4').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')))
    WebMock.stub_request(:get, 'https://smooch.com/video/fake-video.mp4').to_return(status: 200, body: '', headers: {})
    @link_url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: @link_url } }).to_return({ body: '{"type":"media","data":{"url":"' + @link_url + '","type":"item"}}' })
    @link_url_2 = 'https://' + random_string + '.com'
    WebMock.stub_request(:get, pender_url).with({ query: { url: @link_url_2 } }).to_return({ body: '{"type":"media","data":{"url":"' + @link_url_2 + '","type":"item"}}' })
    Bot::Smooch.stubs(:get_language).returns('en')
    create_alegre_bot
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://www.instagram.com/p/Bu3enV8Fjcy' } }).to_return({ body: '{"type":"media","data":{"url":"https://www.instagram.com/p/Bu3enV8Fjcy","type":"item"}}' })
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://www.instagram.com/p/Bu3enV8Fjcy/?utm_source=ig_web_copy_link' } }).to_return({ body: '{"type":"media","data":{"url":"https://www.instagram.com/p/Bu3enV8Fjcy","type":"item"}}' })
    WebMock.stub_request(:get, /check_message_tos/).to_return({ body: '<h1>Check Message Terms of Service</h1><p class="meta">Last modified: August 7, 2019</p>' })
    Bot::Smooch.stubs(:save_user_information).returns(nil)
  end

  def send_message_to_smooch_bot(message = random_string, user = random_string)
    messages = [
      {
        '_id': random_string,
        authorId: user,
        type: 'text',
        text: message
      }
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

  def publish_report(pm = nil, data = {}, report = nil)
    pm ||= create_project_media
    r = report || create_report(pm, data)
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'published' }.to_json
    r.action = 'publish'
    r.save!
    r
  end

  def create_report(pm, data = {}, action = 'save')
    create_report_design_annotation_type if DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last.nil?
    r = create_dynamic_annotation annotation_type: 'report_design', annotated: pm
    default_data = {
      state: 'paused',
      status_label: random_string,
      description: random_string,
      headline: random_string,
      use_visual_card: true,
      use_introduction: true,
      introduction: 'Regarding {{query_message}} on {{query_date}}, it is {{status}}.',
      theme_color: '#FF0000',
      url: random_url,
      use_text_message: true,
      text: random_string,
      use_disclaimer: true,
      disclaimer: random_string
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
end

class MockedClamavClient
  def initialize(response_type)
    @response_type = response_type
  end

  def execute(_input)
    if @response_type == 'virus'
      ClamAV::VirusResponse.new(nil, nil)
    else
      ClamAV::SuccessResponse.new(nil)
    end
  end
end
