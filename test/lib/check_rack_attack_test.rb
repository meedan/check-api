require_relative '../test_helper'

class ThrottlingTest < ActionDispatch::IntegrationTest
  setup do
    @redis = Redis.new(REDIS_CONFIG)
    @redis.flushdb
  end

  def real_ip(request)
    request.get_header('HTTP_CF_CONNECTING_IP') || request.remote_ip
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

      3.times do
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

      3.times do
        post api_user_session_path, params: user_params, as: :json, headers: { 'CF-Connecting-IP' => '1.2.3.4' }
      end

      post api_user_session_path, params: user_params, as: :json, headers: { 'CF-Connecting-IP' => '1.2.3.4' }
      assert_response :forbidden
    end

    Rails.env = original_env
  end

  test "should apply higher rate limit for authenticated users" do
    stub_configs({ 'api_rate_limit_authenticated' => 5 }) do
      host!('localhost')
      password = random_complex_password
      user = create_user password: password
      user_params = { api_user: { email: user.email, password: password } }

      post api_user_session_path, params: user_params, as: :json
      assert_response :success

      5.times do
        post api_graphql_path
        assert_response :success
      end

      post api_graphql_path
      assert_response :too_many_requests

      delete destroy_api_user_session_path, as: :json
      assert_response :success
    end
  end

  test "should not increment counter on successful login" do
    stub_configs({ 'login_block_limit' => 2 }) do
      password = random_complex_password
      user = create_user password: password
      user_params = { api_user: { email: user.email, password: password } }

      3.times do
        post api_user_session_path, params: user_params, as: :json
        assert_response :success
      end

      ip = real_ip(@request)
      counter_value = @redis.get("track:#{ip}")
      assert_nil counter_value, "Counter should not exist after successful logins"
    end
  end

  test "should block IP after excessive invalid login attempts" do
    stub_configs({ 'login_block_limit' => 2 }) do
      password = random_complex_password
      user = create_user password: password

      2.times do
        post api_user_session_path, params: { api_user: { email: user.email, password: 'wrong_password' } }, as: :json
        assert_response :unauthorized
      end

      ip = real_ip(@request)
      counter_value = @redis.get("track:#{ip}")
      assert_equal "2", counter_value, "Counter should be incremented for unsuccessful logins"

      # Subsequent unsuccessful login attempts should result in a blocked IP
      post api_user_session_path, params: { api_user: { email: user.email, password: 'wrong_password' } }, as: :json
      assert_response :forbidden

      assert_equal "true", @redis.get("block:#{ip}")
    end
  end
end
