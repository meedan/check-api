require_relative '../test_helper'

class TerminalStatusMailerTest < ActionMailer::TestCase

	test "should notify editor with terminal status" do
  	t = create_team
    e1 = create_user email: 'editor1@mail.com'
    e2 = create_user email: 'editor2@mail.com'
    e3 = create_user email: 'editor3@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: e1, role: 'editor'
    create_team_user team: t, user: e2, role: 'editor'
    create_team_user team: t, user: e3, role: 'editor'
    create_team_user team: t, user: u, role: 'contributor'
    # bounced one email to verify notification should not send to bounced email
    create_bounce email: e3.email
    p = create_project team: t
    pm = create_project_media project: p
    s = create_status annotated: pm, annotator: u, status: 'false'

    options = { annotated: pm, author: u, status: s}
    emails = TerminalStatusMailer.send_notification(YAML::dump(options))
    assert_equal ['editor1@mail.com', 'editor2@mail.com'].sort, emails.sort
  end
end
