require_relative '../test_helper'

class TeamUserMailerTest < ActionMailer::TestCase

  test "should send request to join email" do
    t = create_team
    o1 = create_user email: 'owner1@mail.com'
    o2 = create_user email: 'owner2@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: o1, role: 'owner'
    create_team_user team: t, user: o2, role: 'owner'
    create_team_user team: t, user: u, role: 'contributor'
    r = create_user

    options = {
      team: t,
      user: u
    }

    emails = TeamUserMailer.send_notification(YAML::dump(options))
    assert_equal ['owner1@mail.com', 'owner2@mail.com'].sort, emails.sort

    info = {
      team: t,
      requestor: u,
      url: "#{CONFIG['checkdesk_client']}/#{t.slug}",
    }

    email = TeamUserMailer.request_to_join(o1.email, info, 'mail subject')

    assert_emails 1 do
      email.deliver_now
    end
  end

  test "should send request to join accepted email" do
    t = create_team
    u = create_user email: 'user@mail.com'

    email = TeamUserMailer.request_to_join_processed(t, u, true)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user@mail.com'], email.to
    assert_match "approved", email.body.parts.first.to_s
  end

  test "should send request to join rejected email" do
    t = create_team
    u = create_user email: 'user@mail.com'

    email = TeamUserMailer.request_to_join_processed(t, u, false)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['user@mail.com'], email.to
    assert_match "not approved", email.body.parts.first.to_s
  end

  test "should not send request to join email if bounced" do
    t = create_team
    o1 = create_user email: 'owner1@mail.com'
    o2 = create_user email: 'owner2@mail.com'
    u = create_user email: 'user@mail.com'
    create_team_user team: t, user: o1, role: 'owner'
    create_team_user team: t, user: o2, role: 'owner'
    create_team_user team: t, user: u, role: 'contributor'
    r = create_user
    create_bounce email: o1.email

    options = {
      team: t,
      user: u
    }

    emails = TeamUserMailer.send_notification(YAML::dump(options))
    assert_equal ['owner2@mail.com'], emails.sort
  end

  test "should not send request to join accepted email if bounced" do
    t = create_team
    u = create_user email: 'user@mail.com'
    create_bounce email: u.email

    email = TeamUserMailer.request_to_join_processed(t, u, true)

    assert_emails 0 do
      email.deliver_now
    end
  end

  test "should not send request to join rejected email if bounced" do
    t = create_team
    u = create_user email: 'user@mail.com'
    create_bounce email: u.email

    email = TeamUserMailer.request_to_join_processed(t, u, false)

    assert_emails 0 do
      email.deliver_now
    end
  end
end
