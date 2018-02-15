require_relative '../test_helper'

class AdminMailerTest < ActionMailer::TestCase
  test "should send download link" do
    p = create_project
    email = AdminMailer.send_download_link(p, 'test@test.com', 'password')
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal ['test@test.com'], email.to
  end
end
