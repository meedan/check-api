require_relative '../test_helper'

class DataExportsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::DataExportsController.new
  end

  test "should access download url" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    de = create_check_data_export user: u, team: t
    de.status = 'generated'
    de.token = random_string
    de.expired_at = Time.now + 1.year
    de.save!
    assert_equal 0, de.use_count
    new_url = random_url
    CheckS3.stubs(:presigned_url).returns(new_url)
    authenticate_with_user(u)
    get :download_exported_data, params: { token: de.token }
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal new_url, response['url']
    assert_equal 1, de.reload.use_count
    get :download_exported_data, params: { token: random_string }
    assert_response 400
  end

  test "should not access download url if the user is different from the original requestor" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    de = create_check_data_export user: u, team: t
    de.status = 'generated'
    de.token = random_string
    de.expired_at = Time.now + 1.year
    de.save!
    assert_equal 0, de.use_count
    u2 = create_user
    create_team_user user: u2, team: t, role: 'admin'
    authenticate_with_user(u2)
    get :download_exported_data, params: { token: de.reload.token }
    assert_response 400
  end
end
