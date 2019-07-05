require_relative '../test_helper'

class AdminMailerTest < ActionMailer::TestCase
  test "should send download link" do
    p = create_project
    requestor = create_user
    email = AdminMailer.send_download_link(:csv, p, requestor.email, 'password')
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [requestor.email], email.to
  end

  test "should include on download link cc only members with notifications enabled" do
    t = create_team
    t.set_max_number_of_members 10
    t.save!
    p = create_project team: t
    requestor = create_user
    member = create_user
    member_without_notifications = create_user
    member_without_notifications.set_send_email_notifications = false; member_without_notifications.save!
    requested = create_user
    invited = create_user
    banned = create_user
    create_team_user team: t, user: requestor, role: 'owner', status: 'member'
    create_team_user team: t, user: member, role: 'owner', status: 'member'
    create_team_user team: t, user: member_without_notifications, role: 'owner', status: 'member'
    create_team_user team: t, user: requested, role: 'owner', status: 'requested'
    create_team_user team: t, user: invited, role: 'owner', status: 'invited'
    create_team_user team: t, user: banned, role: 'owner', status: 'banned'

    email = AdminMailer.send_download_link(:csv, p, requestor.email, 'password')
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [requestor.email], email.to
    assert_equal [member.email], email.cc
  end

  test "should notify import completed" do
    u = create_user
    worksheet_url = 'https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0'
    email = AdminMailer.notify_import_completed(u.email, worksheet_url)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [u.email], email.to
  end

  test "should send team download link" do
    t = create_team
    requestor = create_user
    email = AdminMailer.send_team_download_link(t.slug, 'http://download.com', requestor.email, 'password')
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [requestor.email], email.to
  end

end
