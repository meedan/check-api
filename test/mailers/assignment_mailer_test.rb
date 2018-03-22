require_relative '../test_helper'

class AssignmentMailerTest < ActionMailer::TestCase
  test "should notify about report assignment" do
    u = create_user
    create_user email: 'user1@mail.com'
    t = create_task

    email = AssignmentMailer.notify(:assign_status, u, 'user1@mail.com', t.id)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user1@mail.com'], email.to
  end

   test "should not notify about report assignment if user disable notification" do
    u = create_user
    u2 = create_user email: 'user1@mail.com'
    u2.set_send_email_notifications = false; u2.save!
    t = create_task

    email = AssignmentMailer.notify(:assign_status, u, 'user1@mail.com', t.id)

    assert_emails 0 do
      email.deliver_now
    end
  end
end
