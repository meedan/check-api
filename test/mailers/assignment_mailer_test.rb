require_relative '../test_helper'

class AssignmentMailerTest < ActionMailer::TestCase
  test "should notify about report assignment" do
    u = create_user
    create_user email: 'user1@mail.com'
    t = create_task

    annotation = Annotation.find t.id

    email = AssignmentMailer.notify(:assign_status, u, 'user1@mail.com', annotation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user1@mail.com'], email.to
  end

   test "should not notify about report assignment if user disable notification or banned" do
    u = create_user
    u2 = create_user email: 'user1@mail.com'
    u2.set_send_email_notifications = false; u2.save!
    t = create_task
    annotation = Annotation.find t.id

    email = AssignmentMailer.notify(:assign_status, u, 'user1@mail.com', annotation)

    assert_emails 0 do
      email.deliver_now
    end
    
    # test with banned user
    u3 = create_user email: 'user3@mail.com', is_active: false
    email = AssignmentMailer.notify(:assign_status, u, 'user3@mail.com', annotation)
    assert_emails 0 do
      email.deliver_now
    end
  end


  test "should not crash with non-ASCii e-mail" do
    e = "\u{FEFF}user1@mail.com"
    u = create_user
    u2 = create_user email: e
    t = create_task
    annotation = Annotation.find t.id
    email = AssignmentMailer.notify(:assign_status, u, u2.email, annotation)
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ['user1@mail.com'], email.to
  end
end
