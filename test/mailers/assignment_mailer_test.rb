require_relative '../test_helper'

class AssignmentMailerTest < ActionMailer::TestCase
  test "should notify about report assignment" do
    t = create_team
    u = create_user
    u1 = create_user email: 'user1@mail.com'
    u2 = create_user email: 'user2@mail.com'
    create_team_user team: t, user: u1
    create_team_user team: t, user: u2
    p = create_project team: t
    pm = create_project_media project: p

    email = AssignmentMailer.notify(:assign_report, u, 'user1@mail.com', pm)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user1@mail.com'], email.to
  end
end
