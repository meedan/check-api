require_relative '../test_helper'

class DataExportsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::DataExportsController.new
    # @request.env["devise.mapping"] = Devise.mappings[:api_user]
  end

  test "should accept invitation" do
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
    get :download_exported_data, params: { token: de.token, uid: u.id }
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal new_url, response['url']
    assert_equal 1, de.reload.use_count
    get :download_exported_data, params: { token: random_string, uid: u.id }
    assert_response 400
    get :download_exported_data, params: { token: de.reload.token, uid: random_number }
    assert_response 400
  end
end
