require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BaseApiControllerTest < ActionController::TestCase
  def setup
    super
    Rails.application.routes.draw do
      namespace :api, defaults: { format: 'json' } do
        scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
          match '/test' => 'test#test', via: [:get, :post]
          match '/notify' => 'test#notify', via: [:post]
          get 'version', to: 'base_api#version'
        end
      end
    end
    @controller = Api::V1::TestController.new
  end

  test "should respond to json" do
    assert_equal [:json], @controller.mimes_for_respond_to.keys
  end

  test "should remove empty parameters" do
    get :test, empty: '', notempty: 'Something'
    assert !@controller.params.keys.include?('empty')
    assert @controller.params.keys.include?('notempty')
  end

  test "should remove empty headers" do
    @request.headers['X-Empty'] = ''
    @request.headers['X-Not-Empty'] = 'Something'
    get :test
    assert @request.headers['X-Empty'].nil?
    assert !@request.headers['X-Not-Empty'].nil?
  end

  test "should return build as a custom header" do
    get :test
    assert_not_nil @response.headers['X-Build']
  end

  test "should return default api version as a custom header" do
    get :test
    assert_match /v1$/, @response.headers['Accept']
  end

  test "should filter parameters" do
    authenticate_with_token
    get :test, foo: 'bar'
    assert_equal ['foo'], assigns(:p).keys
  end

  test "should not access without token" do
    get :test
    assert_response 401
  end

  test "should access with token" do
    authenticate_with_token
    get :test
    assert_response :success
  end

  test "should parse webhook payload" do
    payload = { foo: 'bar' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :notify
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
  end

  test "should return authentication error when parsing webhook" do
    payload = { foo: 'bar' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), 'invalid_token', payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :notify
    @request.env.delete('RAW_POST_DATA')
    assert_response 401
  end

  test "should return unknown error when parsing webhook" do
    payload = nil
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), 'invalid_token', payload.to_s)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :notify
    @request.env.delete('RAW_POST_DATA')
    assert_response 400
  end

  test "should get version" do
    authenticate_with_token
    @controller = Api::V1::BaseApiController.new
    get :version
    assert_response :success
  end
end
