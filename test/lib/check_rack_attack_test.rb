require 'test_helper'

class ThrottlingTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "should throttle excessive requests to /api/graphql" do
    stub_configs({ 'api_rate_limit' => 2 }) do
      3.times do
        post api_graphql_path
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
end
