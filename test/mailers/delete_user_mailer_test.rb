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

    emails = DeleteUserMailer.send_owner_notification(u, t)

    assert_equal ['owner1@mail.com', 'owner2@mail.com'].sort, emails.sort

    email = DeleteUserMailer.notify_owners(o1.email, u, t)
    assert_emails 1 do
      email.deliver_now
    end

    stub_config 'privacy_email', 'privacy_email@local.com' do
      email = DeleteUserMailer.notify_privacy(u)
      assert_emails 1 do
        email.deliver_now
      end
      assert_equal ['privacy_email@local.com'], email.to
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


    emails = DeleteUserMailer.send_owner_notification(u, t)

    assert_equal ['owner3@mail.com'].sort, emails.sort

  end
end
