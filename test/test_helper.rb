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

  def notify
    render_success 'success', @payload
  end
end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  include SampleData

  # This will run before any test

  def setup
    Rails.cache.clear if File.exists?(File.join(Rails.root, 'tmp', 'cache'))
    Rails.application.reload_routes!
    # URL mocked by pender-client
    @url = 'https://www.youtube.com/user/MeedanTube'
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

  def authenticate_with_user(user = create_user)
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
    
    assert_response :success
  end

  def assert_graphql_read(type, field = 'id')
    type.camelize.constantize.delete_all
    x1 = send("create_#{type}")
    x2 = send("create_#{type}")
    user = type == 'user' ? x1 : create_user
    authenticate_with_user(user)
    post :create, query: "query read { root { #{type.pluralize} { edges { node { #{field} } } } } }"
    yield if block_given?
    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    assert_equal 2, edges.size
    assert_equal x1.send(field), edges[0]['node'][field]
    assert_equal x2.send(field), edges[1]['node'][field]
    assert_response :success
  end

  def assert_graphql_update(type, attr, from, to)
    authenticate_with_user
    obj = send("create_#{type}", { attr => from })
    klass = obj.class.to_s
    assert_equal from, obj.send(attr)
    id = NodeIdentification.to_global_id(klass, obj.id)
    input = '{ clientMutationId: "1", id: "' + id.to_s + '", ' + attr.to_s + ': ' + to.to_json + ' }'
    post :create, query: "mutation update { update#{klass}(input: #{input}) { #{type} { #{attr} } } }"
    yield if block_given?
    assert_response :success
    assert_equal to, obj.reload.send(attr)
  end

  def assert_graphql_destroy(type)
    authenticate_with_user
    obj = send("create_#{type}")
    klass = obj.class.name
    id = NodeIdentification.to_global_id(klass, obj.id)
    assert_difference "#{klass}.count", -1 do
      post :create, query: "mutation destroy { destroy#{klass}(input: { clientMutationId: \"1\", id: \"#{id}\" }) { deletedId } }"
      yield if block_given?
    end
    assert_response :success
  end

  def assert_graphql_read_object(type, fields = {})
    authenticate_with_user
    type.camelize.constantize.delete_all
    x1 = send("create_#{type}")
    x2 = send("create_#{type}")
    
    node = '{ '
    fields.each do |name, key|
      node += "#{name} { #{key} }, "
    end
    node.gsub!(/, $/, ' }')

    post :create, query: "query read { root { #{type.pluralize} { edges { node #{node} } } } }"
    yield if block_given?
    
    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    assert_equal 2, edges.size
    
    fields.each { |name, key| assert_equal x1.send(name).send(key), edges[0]['node'][name][key] }
    fields.each { |name, key| assert_equal x2.send(name).send(key), edges[1]['node'][name][key] }
    
    assert_response :success
  end

  def assert_graphql_read_collection(type, fields = {})
    authenticate_with_user
    type.camelize.constantize.delete_all
    
    obj = send("create_#{type}")
    
    node = '{ '
    fields.each do |name, key|
      obj.send(name).send('<<', [send("create_#{name.singularize}")])
      obj.save!
      node += "#{name} { edges { node { #{key} } } }, "
    end
    node.gsub!(/, $/, ' }')
    
    post :create, query: "query read { root { #{type.pluralize} { edges { node #{node} } } } }"
    yield if block_given?
    
    edges = JSON.parse(@response.body)['data']['root'][type.pluralize]['edges']
    
    fields.each { |name, key| assert_equal obj.send(name).first.send(key), edges[0]['node'][name]['edges'][0]['node'][key] }
    
    assert_response :success
  end
end
