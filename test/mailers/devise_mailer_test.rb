require_relative '../test_helper'

class DeviseMailerTest < ActionMailer::TestCase

  test "should send confirmation e-mail" do
    u = create_user name: 'Test User', email: 'test@mail.com'

    email = DeviseMailer.confirmation_instructions(u, '123456')

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [CONFIG['default_mail']], email.from
    assert_equal ['test@mail.com'], email.to
    assert_match "confirmation_token=#{u.confirmation_token}", email.body.parts.first.to_s
  end

  test "should send reset password instructions" do
    u = create_user name: 'Test User', email: 'test@mail.com'
    email = DeviseMailer.reset_password_instructions(u, '12345')

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [CONFIG['default_mail']], email.from
    assert_equal ['test@mail.com'], email.to
    assert_match "reset_password_token=12345", email.body.to_s
  end

  test "should send invitation email" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    u1 = create_user email: 'test1@local.com'
    with_current_user_and_team(u, t) do
      members = [{role: 'contributor', email: u1.email}]
      User.send_user_invitation(members)
    end
    tu = u1.reload.team_users.last
    token = tu.raw_invitation_token
    opts = {due_at: tu.invitation_due_at, invitation_text: '', invitation_team: t}
    email = DeviseMailer.invitation_instructions(u1, token, opts)
    assert_emails 1 do
      email.deliver_now
    end
  end

end
