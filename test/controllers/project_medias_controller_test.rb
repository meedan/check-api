require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectMediasControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::ProjectMediasController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
    ProjectMedia.delete_all
  end

  test "should not get oembed of absent media" do
    pm = create_project_media
    get :oembed, id: pm.id + 1
    assert_response 404
  end

  test "should not get oembed of private media" do
    t = create_team private: true
    p = create_project team: t
    pm = create_project_media project: p
    get :oembed, id: pm.id
    assert_response 401
  end

  test "should get oembed of existing media" do
    pm = create_project_media
    get :oembed, id: pm.id
    assert_response :success
  end

  test "should allow iframe" do
    pm = create_project_media
    get :oembed, id: pm.id
    assert !@response.headers.include?('X-Frame-Options')
  end
end
