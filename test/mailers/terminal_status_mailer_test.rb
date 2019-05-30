require_relative '../test_helper'

class TerminalStatusMailerTest < ActionMailer::TestCase

	test "should notify editor with terminal status" do
  	t = create_team
    e1 = create_user email: 'editor1@mail.com'
    e2 = create_user email: 'editor2@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: e1, role: 'editor'
    create_team_user team: t, user: e2, role: 'editor'
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    s = create_status annotated: pm, annotator: u, status: 'false'

    email = TerminalStatusMailer.notify(e1.email, pm, u, s.status)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [CONFIG['default_mail']], email.from
  end

  test "should not notify editor with terminal status if bounced or notification disabled" do
  	t = create_team
    e1 = create_user email: 'editor1@mail.com'
    e2 = create_user email: 'editor2@mail.com'
    e3 = create_user email: 'editor3@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: e1, role: 'editor'
    create_team_user team: t, user: e2, role: 'editor'
    create_team_user team: t, user: e3, role: 'editor'
    create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    s = create_status annotated: pm, annotator: u, status: 'false'

    create_bounce email: e1.email

    e2.set_send_email_notifications = false; e2.save!
    
    email = TerminalStatusMailer.send_notification(e3.email, pm, u, s.status)

    assert_emails 1 do
      email.deliver_now
    end

  end
end
