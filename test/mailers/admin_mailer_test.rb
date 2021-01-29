require_relative '../test_helper'

class AdminMailerTest < ActionMailer::TestCase
  test "should notify import completed" do
    u = create_user
    worksheet_url = 'https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0'
    email = AdminMailer.notify_import_completed(u.email, worksheet_url)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [u.email], email.to
  end
end
