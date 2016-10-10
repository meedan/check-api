ENV['RAILS_ENV'] ||= 'test'
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'mocha/test_unit'
require 'sample_data'

class ActionController::TestCase
  include Devise::TestHelpers
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

  # This will run before any test

  def setup
    [Media, Account, Source, User].each{ |m| m.destroy_all }
    Rails.cache.clear if File.exists?(File.join(Rails.root, 'tmp', 'cache'))
    Rails.application.reload_routes!
    # URL mocked by pender-client
    @url = 'https://www.youtube.com/user/MeedanTube'
    @team = create_team
    @project = create_project team: @team
    CheckdeskNotifications::Slack::Request.any_instance.stubs(:request).returns(nil)
  end

  # This will run after any test

  def teardown
    WebMock.reset!
    WebMock.allow_net_connect!
    Time.unstub(:now)
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
      yield if block_given?
    end

    document_graphql_query('create', type, query, @response.body)
    
    assert_response :success
  end

  def assert_graphql_read(type, field = 'id')
    klass = type.camelize.constantize
    u = create_user
    klass.delete_all
    x1 = send("create_#{type}", { team: @team })
    x2 = send("create_#{type}", { team: @team })
    user = type == 'user' ? x1 : u
    authenticate_with_user(user)
    query = "query read { root { #{type.pluralize} { edges { node { #{field} } } } } }"
    post :create, query: query 
    yield if block_given?
    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    assert_equal klass.count, edges.size
    assert_equal x1.send(field), edges[0]['node'][field]
    assert_equal x2.send(field), edges[1]['node'][field]
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
    id = NodeIdentification.to_global_id(klass, obj.id)
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
    klass = obj.class.name
    id = NodeIdentification.to_global_id(klass, obj.id)
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
      x1 = create_comment.reload
      x2 = create_comment.reload
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
    
    fields.each { |name, key| assert_equal x1.send(name).send(key), edges[0]['node'][name][key] }
    fields.each { |name, key| assert_equal x2.send(name).send(key), edges[1]['node'][name][key] }
    
    assert_response :success
    document_graphql_query('read_object', type, query, @response.body)
  end

  def assert_graphql_read_collection(type, fields = {}, order = 'ASC')
    type.camelize.constantize.delete_all
    
    obj = send("create_#{type}")
    
    node = '{ '
    fields.each do |name, key|
      if name === 'medias' && obj.is_a?(Source)
        create_valid_media(account: create_valid_account(source: obj))
        obj = obj.reload
      elsif name === 'collaborators'
        obj.add_annotation create_comment(annotator: create_user)
        sleep 1
      elsif name === 'annotations' || name === 'comments'
        obj.add_annotation(create_comment) if obj.annotations.empty?
        sleep 1
      elsif name === 'tags'
        obj.add_annotation(create_tag)
        sleep 1
      else
        obj.send(name).send('<<', [send("create_#{name.singularize}")])
        obj.save!
      end
      node += "#{name} { edges { node { #{key} } } }, "
    end
    node.gsub!(/, $/, ' }')
    
    query = "query read { root { #{type.pluralize} { edges { node #{node} } } } }"
    type === 'user' ? authenticate_with_user(obj) : authenticate_with_user
    
    post :create, query: query
    
    yield if block_given?
    
    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    
    nindex = order === 'ASC' ? 0 : (type.camelize.constantize.count - 1)
    fields.each { |name, key| assert_equal obj.send(name).first.send(key), edges[nindex]['node'][name]['edges'][0]['node'][key] }
    
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
