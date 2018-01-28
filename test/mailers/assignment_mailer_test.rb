require_relative '../test_helper'

class AssignmentMailerTest < ActionMailer::TestCase
  test "should notify about report assignment" do
    u = create_user
    t = create_task

    email = AssignmentMailer.notify(:assign_status, u, 'user1@mail.com', t.id)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user1@mail.com'], email.to
  end
end
