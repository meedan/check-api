require "test_helper"

class FeedInvitationMailerTest < ActionMailer::TestCase
  test "should notify about feed invitation" do
    fi = create_feed_invitation
    t = create_team
    email = FeedInvitationMailer.notify(fi.id, t.id)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [fi.email], email.to
  end
end
