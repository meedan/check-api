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

    email = TerminalStatusMailer.notify(pm, u, s.status)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [CONFIG['default_mail']], email.from
    assert_equal ['editor1@mail.com', 'editor2@mail.com'].sort, email.to.sort
  end

  test "should not notify editor with terminal status if bounced" do
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

    create_bounce email: e1.email
    
    email = TerminalStatusMailer.notify(pm, u, s.status)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['editor2@mail.com'].sort, email.to.sort
  end
end
