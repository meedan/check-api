require_relative '../test_helper'

class InvitationsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::InvitationsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
  end

  test "should accept invitation" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    u1 = create_user email: 'test1@local.com'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: u1.email}]
      User.send_user_invitation(members)
    end
    tu =  u1.team_users.last
    token = tu.raw_invitation_token
    get :edit, invitation_token: token, slug: t.slug
    assert_redirected_to "#{CONFIG['checkdesk_client']}/?invitation_response=success&msg=no"
    assert_nil tu.reload.invitation_token
  end

  test "should not accept invalid invitation" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    u1 = create_user email: 'test1@local.com'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: u1.email}]
      User.send_user_invitation(members)
    end
    tu =  u1.team_users.last
    token = tu.raw_invitation_token
    get :edit, invitation_token: 'invalid-token', slug: t.slug
    assert_redirected_to "#{CONFIG['checkdesk_client']}/?invitation_response=no_invitation"
    assert_not_nil tu.reload.invitation_token
    get :edit, invitation_token: token, slug: 'invalid-slug'
    assert_not_nil tu.reload.invitation_token
    assert_redirected_to "#{CONFIG['checkdesk_client']}/?invitation_response=invalid_team"
  end

end
