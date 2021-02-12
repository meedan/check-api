require_relative '../test_helper'

class ApiVersionIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    super
  end

  test "should get default version 1" do
    get '/api/version'
    assert_response 401
  end

  test "should get version 2" do
    headers = { 'Accept' => 'application/vnd.lapis.v2' }
    get '/api/version', headers, headers
    assert_response 200
  end
end
