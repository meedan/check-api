require_relative '../test_helper'

class DeleteUserMailerTest < ActionMailer::TestCase

	test "should notify owner(s) and privacy with deleted user" do
  	t = create_team
    o1 = create_user email: 'owner1@mail.com'
    o2 = create_user email: 'owner2@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: o1, role: 'owner'
    create_team_user team: t, user: o2, role: 'owner'
    create_team_user team: t, user: u, role: 'contributor'

    stub_configs({ 'privacy_email' => 'privacy_email@local.com' }) do
      emails = DeleteUserMailer.send_notification(u, [t])
      assert_equal ['owner1@mail.com', 'owner2@mail.com', 'privacy_email@local.com'].sort, emails.sort
    end

    email = DeleteUserMailer.notify(o1.email, u, t)
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "should not notify owner if bounced" do
  	t = create_team
    o1 = create_user email: 'owner1@mail.com'
    o3 = create_user email: 'owner3@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: o1, role: 'owner'
    create_team_user team: t, user: o3, role: 'owner'
    create_team_user team: t, user: u, role: 'contributor'

    create_bounce email: o1.email

    stub_configs({ 'privacy_email' => '' }) do
      emails = DeleteUserMailer.send_notification(u, [t])
      assert_equal ['owner3@mail.com'].sort, emails.sort
    end

  end
end
