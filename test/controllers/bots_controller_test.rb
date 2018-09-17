require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BotsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::BotsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    t = create_team
    t.set_limits_keep = true
    t.save!
    p = create_project team: t
    pm = create_project_media project: p
    @request.env['RAW_POST_DATA'] = { data: { dbid: pm.id }, user_id: create_user(is_admin: true).id }.to_json
    User.current = nil
    create_annotation_type_and_fields('Keep Backup', { 'Response' => ['JSON', false] })
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
  end

  test "should call endpoint if call is from inside" do
    stub_config('checkdesk_base_url_private', 'http://test.host') do
      assert_difference 'Annotation.count' do
        get :index, name: :keep
        assert_response :success
      end
    end
  end

  test "should not call endpoint if call is not from inside" do
    stub_config('checkdesk_base_url_private', 'http://something.com') do
      get :index, name: :keep
      assert_response 400
    end
  end

  test "should return error if bot does not exist" do
    stub_config('checkdesk_base_url_private', 'http://test.host') do
      get :index, name: :test
      assert_response 404
    end
  end
end
