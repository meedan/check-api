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

  test "should notify about project assignment" do
    u = create_user
    create_user email: 'user1@mail.com'
    p = create_project

    email = AssignmentMailer.notify(:assign_project, u, 'user1@mail.com', p)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user1@mail.com'], email.to
  end

  test "should send e-mail when assignments are ready" do
    u = create_user email: 'user1@mail.com'
    u2 = create_user
    t = create_team
    p = create_project team: t

    email = AssignmentMailer.ready(u, t, p, :assign, u2)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user1@mail.com'], email.to
  end

  test "should not send e-mail if there is no e-mail" do
    u = create_user email: '', provider: 'twitter'
    u2 = create_user email: '', provider: 'twitter'
    t = create_team
    p = create_project team: t

    email = AssignmentMailer.ready(u, t, p, :assign, u2)

    assert_nothing_raised do
      assert_emails 0 do
        email.deliver_now
      end
    end
  end
end
