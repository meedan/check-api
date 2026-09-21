require_relative '../test_helper'

class SunsetMailerTest < ActionMailer::TestCase
  test 'should notify about requested data export' do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    de = create_check_data_export user: u, team: t
    email = SunsetMailer.request_export_notification(de.id)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [CheckConfig.get('support_email')], email.to
  end

  test 'should notify about generated data export' do
    u = create_user
    t = create_team
    email = SunsetMailer.notify('download', u.id, t.id)
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [u.email], email.to
  end
end
