require_relative '../test_helper'

class UpdatedTermsMailerTest < ActionMailer::TestCase
  test 'should notify about terms update' do
    u = create_user
    email = UpdatedTermsMailer.notify(u.email, u.name)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [u.email], email.to
  end
end
