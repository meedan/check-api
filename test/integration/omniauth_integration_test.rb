require_relative '../test_helper'

class OmniauthIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    redis = Redis.new(REDIS_CONFIG)
    redis.flushdb
  end

  test "should close in case of failure" do
    get '/api/users/auth/slack/callback', params: { error: 'access_denied' }
    assert_redirected_to '/close.html'
  end
end
