require 'simplecov'

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

  def stub_config(key, value)
    CONFIG.each do |k, v|
      CONFIG.stubs(:[]).with(k).returns(v) if k != key
    end
    CONFIG.stubs(:[]).with(key).returns(value)
    yield if block_given?
    CONFIG.unstub(:[])
  end

  def stub_configs(configs)
    CONFIG.each do |k, v|
      CONFIG.stubs(:[]).with(k).returns(v) unless configs.keys.include?(k)
    end
    configs.each do |k, v|
      CONFIG.stubs(:[]).with(k).returns(v)
    end
    yield if block_given?
    CONFIG.unstub(:[])
  end

  def with_current_user_and_team(user = nil, team = nil)
    Team.stubs(:current).returns(team)
    User.stubs(:current).returns(user.nil? ? nil : user.reload)
    begin
      yield if block_given?
    rescue Exception => e
      raise e
    ensure
      User.unstub(:current)
      Team.unstub(:current)
    end
  end

  # This will run before any test

  def setup
    ApolloTracing.stubs(:start_proxy)
    Pusher::Client.any_instance.stubs(:trigger)
    WebMock.stub_request(:post, /#{Regexp.escape(CONFIG['bridge_reader_url_private'])}.*/) unless CONFIG['bridge_reader_url_private'].blank?
    [Account, Media, ProjectMedia, User, Source, Annotation, Team, TeamUser, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldType, DynamicAnnotation::FieldInstance, Relationship].each{ |klass| klass.delete_all }
    FileUtils.rm_rf(File.join(Rails.root, 'tmp', "cache<%= ENV['TEST_ENV_NUMBER'] %>", '*'))
    Rails.application.reload_routes!
    # URL mocked by pender-client
    @url = 'https://www.youtube.com/user/MeedanTube'
    with_current_user_and_team(nil, nil) do
      @team = create_team
      @project = create_project team: @team
    end
    ApiKey.current = User.current = Team.current = nil
    ProjectMedia.any_instance.stubs(:clear_caches).returns(nil)
    I18n.locale = :en
    Sidekiq::Worker.clear_all
    Rails.cache.clear
    RequestStore.unstub(:[])
  end

  # This will run after any test

  def teardown
    WebMock.reset!
    WebMock.allow_net_connect!
    Time.unstub(:now)
    Rails.unstub(:env)
    RequestStore.unstub(:[])
    User.current = nil
  end

  def assert_queries(num = 1, operator = '=', &block)
    old = ActiveRecord::Base.connection.query_cache_enabled
    ActiveRecord::Base.connection.enable_query_cache!
    queries  = []
    callback = lambda { |name, start, finish, id, payload|
      queries << payload[:sql] if payload[:sql] =~ /^SELECT|UPDATE|INSERT/ and payload[:name] != 'CACHE'
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
  ensure
    ActiveRecord::Base.connection.disable_query_cache! unless old
    msg = "#{queries.size} expected to be #{operator} #{num}.#{queries.size == 0 ? '' : "\nQueries:\n#{queries.join("\n")}"}"
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
      token ||= create_user.token
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
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_task', label: 'Note', field_type_object: ft1
    fi3 = create_field_instance annotation_type_object: at, name: 'task_reference', label: 'Task', field_type_object: ft2
    tk = create_task annotated: pm
    tk.disable_es_callbacks = true
    tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Test', task_reference: tk.id.to_s }.to_json }.to_json
    tk.save!

    a = Dynamic.where(annotation_type: 'task_response_free_text').last

    assert_equal '', a.attribution

    with_current_user_and_team(u1, t) do
      a = Dynamic.find(a.id)
      a.set_fields = { response_task: 'Test 1', task_reference: tk.id.to_s }.to_json
      a.save!
      assert_equal [u1.id].join(','), a.reload.attribution
    end

    with_current_user_and_team(u2, t) do
      a = Dynamic.find(a.id)
      a.set_fields = { response_task: 'Test 2', task_reference: tk.id.to_s }.to_json
      a.save!
      assert_equal [u1.id, u2.id].join(','), a.reload.attribution
    end

    with_current_user_and_team(u2, t) do
      a = Dynamic.find(a.id)
      a.set_attribution = u1.id.to_s
      a.set_fields = { response_task: 'Test 3', task_reference: tk.id.to_s }.to_json
      a.save!
      assert_equal [u1.id].join(','), a.reload.attribution
    end

    with_current_user_and_team(u3, t) do
      a = Dynamic.find(a.id)
      a.set_fields = { response_task: 'Test 4', task_reference: tk.id.to_s }.to_json
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
    assert_equal klass.count, edges.size
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

  def create_translation_status_stuff(delete_existing = true)
    if delete_existing
      [DynamicAnnotation::FieldType, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldInstance].each { |klass| klass.delete_all }
    end
    ft1 = DynamicAnnotation::FieldType.where(field_type: 'select').last || create_field_type(field_type: 'select', label: 'Select')
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'translation_status', label: 'Translation Status'
    create_field_instance annotation_type_object: at, name: 'translation_status_status', label: 'Translation Status', default_value: 'pending', field_type_object: ft1, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_status_note', label: 'Translation Status Note', field_type_object: ft2, optional: true
    create_field_instance annotation_type_object: at, name: 'translation_status_approver', label: 'Translation Status Approver', field_type_object: ft2, optional: true
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
