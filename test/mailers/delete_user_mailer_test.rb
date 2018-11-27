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

    email = DeleteUserMailer.notify_owners(u)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal ['owner1@mail.com', 'owner2@mail.com'].sort, email.to.sort

    stub_config 'privacy_email', 'privacy_email@local.com' do
      email = DeleteUserMailer.notify_privacy(u)
      assert_emails 1 do
        email.deliver_now
      end
      assert_equal ['privacy_email@local.com'], email.to
    end
  end

  test "should not notify owner if bounced or notification disabled" do
  	t = create_team
    o1 = create_user email: 'owner1@mail.com'
    o2 = create_user email: 'owner2@mail.com'
    o3 = create_user email: 'owner3@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: o1, role: 'owner'
    create_team_user team: t, user: o2, role: 'owner'
    create_team_user team: t, user: o3, role: 'owner'
    create_team_user team: t, user: u, role: 'contributor'

    create_bounce email: o1.email

    o2.set_send_email_notifications = false; o2.save!

    email = DeleteUserMailer.notify_owners(u)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['owner3@mail.com'].sort, email.to.sort
  end
end
