require 'test_helper'

class ThrottlingTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "should throttle excessive requests to /api/graphql" do
    limit = 100

    limit.times do
      post api_graphql_path
      assert_response :unauthorized
    end

    get api_graphql_path
    assert_response :too_many_requests
  end

  test "should throttle excessive requests to /api/users/sign_in" do
    limit = 10
    user_params = { api_user: { email: 'user@example.com', password: 'password' } }

    limit.times do
      post api_user_session_path, params: user_params, as: :json
    end

    post api_user_session_path, params: user_params, as: :json
    assert_response :too_many_requests
  end
end
