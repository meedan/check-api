require_relative '../test_helper'

class DeviseMailerTest < ActionMailer::TestCase

  test "should send confirmation e-mail" do
    u = create_user name: 'Test User', email: 'test@mail.com'
    email = DeviseMailer.confirmation_instructions(u, '123456')
    assert_emails 1 do
      email.deliver_now
    end
    assert_match email.from.first, CheckConfig.get('default_mail')
    assert_equal ['test@mail.com'], email.to
    assert_match "confirmation_token=#{u.confirmation_token}", email.body.parts.first.to_s
  end

  test "should send reset password instructions" do
    u = create_user name: 'Test User', email: 'test@mail.com'
    email = DeviseMailer.reset_password_instructions(u, '12345')
    assert_emails 1 do
      email.deliver_now
    end
    assert_match email.from.first, CheckConfig.get('default_mail')
    assert_equal ['test@mail.com'], email.to
  end

  test "should send invitation email" do
    t = create_team
    u = create_user email: 'primary@local.com'
    create_team_user team: t, user: u, role: 'admin'
    u1 = create_user email: 'test1@local.com'
    with_current_user_and_team(u, t) do
      members = [{role: 'collaborator', email: u1.email}]
      User.send_user_invitation(members)
    end
    tu = u1.reload.team_users.last
    token = tu.raw_invitation_token
    opts = {due_at: tu.invitation_due_at, invitation_text: '', invitation_team: t}
    email = DeviseMailer.invitation_instructions(u1, token, opts)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal ["test1@local.com"], email.to
    # should user invitation email for notification
    a = create_account source: u.source, user: u, provider: 'facebook', email: 'account@local.com'
    t2 = create_team
    create_team_user user: u1, team: t2, role: 'admin'
    # invite existing user
    members = [{role: 'collaborator', email: 'account@local.com'}]
    # A) for same team
    with_current_user_and_team(u1, t2) do
      User.send_user_invitation(members)
    end
    tu = u.reload.team_users.where(team: t2).last
    token = tu.raw_invitation_token
    opts = {due_at: tu.invitation_due_at, invitation_text: '', invitation_team: t2}
    email = DeviseMailer.invitation_instructions(u, token, opts)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal ['account@local.com'], email.to
  end
end
