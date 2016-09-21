require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SearchControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::SearchController.new
  end

  test "should get create" do
    get :create
    assert_response :success
  end

end
