require_relative '../test_helper'

class BaseApiControllerV2Test < ActionController::TestCase
  def setup
    super
    @controller = Api::V2::BaseApiController.new
  end

  test "should respond to json" do
    assert_equal [:json], @controller.mimes_for_respond_to.keys
  end

  test "should get version" do
    authenticate_with_token
    get :version, params: {}
    assert_response :success
  end

  test "should get ping" do
    get :ping, params: {}
    assert_response :success
  end

  test "should get options" do
    process :options, params: {}
    assert_response :success
  end
end
