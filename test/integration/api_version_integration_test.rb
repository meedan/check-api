require_relative '../test_helper'

class ApiVersionIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    redis = Redis.new(REDIS_CONFIG)
    redis.flushdb
  end

  test "should get default version 1" do
    get '/api/version', params: {}
    assert_response 401
  end

  test "should get version 2" do
    headers = { 'Accept' => 'application/vnd.lapis.v2' }
    get '/api/version', params: {}, headers: headers
    assert_response 401
  end
end
