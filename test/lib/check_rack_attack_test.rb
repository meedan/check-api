require 'test_helper'

class ThrottlingTest < ActionDispatch::IntegrationTest
  setup do
    redis = Redis.new(REDIS_CONFIG)
    redis.flushdb
  end

  test "should throttle excessive requests to /api/graphql" do
    stub_configs({ 'api_rate_limit' => 3 }) do
      3.times do
        post api_graphql_path
        assert_response :unauthorized
      end

      post api_graphql_path
      assert_response :too_many_requests
    end
  end

  test "should block IPs with excessive repeated requests to /api/users/sign_in" do
    stub_configs({ 'login_block_limit' => 2 }) do
      user_params = { api_user: { email: 'user@example.com', password: random_complex_password } }

      2.times do
        post api_user_session_path, params: user_params, as: :json
      end

      post api_user_session_path, params: user_params, as: :json
      assert_response :forbidden
    end
  end

  test "should handle requests via Cloudflare correctly in production" do
    original_env = Rails.env
    Rails.env = 'production'

    stub_configs({ 'api_rate_limit' => 3, 'login_block_limit' => 2 }) do
      # Test throttling for /api/graphql via Cloudflare
      3.times do
        post api_graphql_path, headers: { 'CF-Connecting-IP' => '1.2.3.4' }
        assert_response :unauthorized
      end

      post api_graphql_path, headers: { 'CF-Connecting-IP' => '1.2.3.4' }
      assert_response :too_many_requests

      # Test blocking for /api/users/sign_in via Cloudflare
      user_params = { api_user: { email: 'user@example.com', password: random_complex_password } }

      2.times do
        post api_user_session_path, params: user_params, as: :json, headers: { 'CF-Connecting-IP' => '1.2.3.4' }
      end

      post api_user_session_path, params: user_params, as: :json, headers: { 'CF-Connecting-IP' => '1.2.3.4' }
      assert_response :forbidden
    end

    Rails.env = original_env
  end
end
