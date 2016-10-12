require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class TeamTest < ActiveSupport::TestCase
  test "should create team" do
    assert_difference 'Team.count' do
      create_team
    end
    assert_difference 'Team.count' do
      u = create_user
      create_team current_user: u
    end
  end

  test "non memebers should not access private team" do
    u = create_user
    t = create_team current_user: create_user
    pu = create_user
    pt = create_team current_user: pu, private: true
    Team.find_if_can(t.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      Team.find_if_can(pt.id, u, pt)
    end
    Team.find_if_can(pt.id, pu, pt)
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      Team.find_if_can(pt.id, pu, pt)
    end
    assert_raise CheckdeskPermissions::AccessDenied do
      Team.find_if_can(pt, create_user, pt)
    end
  end

  test "should update and destroy team" do
    u = create_user
    t = create_team current_user: u
    t.current_user = u
    t.name = 'meedan'; t.save!
    t.reload
    assert_equal t.name, 'meedan'
    # update team as editor
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    t.current_user = u2
    t.name = 'meedan_mod'; t.save!
    t.reload
    assert_equal t.name, 'meedan_mod'
    assert_raise RuntimeError do
      t.current_user = u2
      t.destroy
    end
    tu.role = 'journalist'; tu.save!
    assert_raise RuntimeError do
      t.current_user = u2
      t.save!
    end
  end

  test "should not save team without name" do
    t = Team.new
    assert_not t.save
  end

  test "should not save team with invalid subdomains" do
    assert_nothing_raised do
      create_team subdomain: "correct-الصهث-unicode"
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team subdomain: ''
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team subdomain: 'www'
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team subdomain: ''.rjust(64, 'a')
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team subdomain: ' some spaces '
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team subdomain: 'correct-الصهث-unicode'
    end
  end

  test "should create version when team is created" do
    t = create_team
    assert_equal 1, t.versions.size
  end

  test "should create version when team is updated" do
    t = create_team
    t.logo = random_string
    t.save!
    assert_equal 2, t.versions.size
  end

  test "should have users" do
    t = create_team
    u1 = create_user
    u2 = create_user
    assert_equal [], t.users
    t.users << u1
    t.users << u2
    assert_equal [u1, u2], t.users
  end

  test "should have team users" do
    t = create_team
    u1 = create_user
    u2 = create_user
    tu1 = create_team_user user: u1
    tu2 = create_team_user user: u2
    assert_equal [], t.team_users
    t.team_users << tu1
    t.team_users << tu2
    assert_equal [tu1, tu2], t.team_users
    assert_equal [u1, u2], t.users
  end

  test "should get logo from callback" do
    t = create_team
    assert_nil t.logo_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil t.logo_callback(file)
    file = 'http://ca.ios.ba/files/others/rails.png'
    assert_not_nil t.logo_callback(file)
  end

  test "should add user to team on team creation" do
    u = create_user
    assert_difference 'TeamUser.count' do
      create_team current_user: u
    end
  end

  test "should not add user to team on team creation" do
    assert_no_difference 'TeamUser.count' do
      create_team current_user: nil
    end
  end

  test "should not upload a logo that is not an image" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big logo" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small logo" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'ruby-small.png'
      end
    end
  end

  test "should have a default uploaded image" do
    t = create_team logo: nil
    assert_match /team\.png$/, t.logo.url
  end

  test "should have avatar" do
    t = create_team logo: nil
    assert_match /^http/, t.avatar
  end

  test "should have members count" do
    t = create_team
    t.users << create_user
    t.users << create_user
    assert_equal 2, t.members_count
  end

  test "should have a JSON version" do
    assert_kind_of Hash, create_team.as_json
  end

  test "should not send email when team is created" do
    u = create_user
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference 'TeamUser.count' do
        create_team current_user: u
      end
    end
  end

  test "should set current team when team is created by user" do
    t1 = create_team
    u = create_user
    create_team_user user: u, team: t1
    u.current_team_id = t1.id
    u.save!
    assert_equal t1, u.reload.current_team
    t2 = create_team current_user: u
    assert_equal t2, u.reload.current_team
  end

  test "should not create team with reserved subdomain from subdomain origin" do
    WebMock.stub_request(:head, 'http://pender.checkmedia.org').to_return(body: 'Pender', status: 200, headers: {})
    stub_config('checkdesk_client', '^https?:\/\/([a-zA-Z0-9\-]*)\.?checkmedia.org.*') do
      assert_raises ActiveRecord::RecordInvalid do
        create_team subdomain: 'pender', origin: 'http://team.checkmedia.org'
      end
    end
  end

  test "should not create team with reserved subdomain from origin" do
    WebMock.stub_request(:head, 'http://pender.checkmedia.org').to_return(body: 'Pender', status: 200, headers: {})
    stub_config('checkdesk_client', '^https?:\/\/([a-zA-Z0-9\-]*)\.?checkmedia.org.*') do
      assert_raises ActiveRecord::RecordInvalid do
        create_team subdomain: 'pender', origin: 'http://checkmedia.org'
      end
    end
  end

  test "should create team with reserved subdomain" do
    WebMock.stub_request(:head, 'http://pender.checkmedia.org').to_return(body: 'Pender', status: 200, headers: {})
    stub_config('checkdesk_client', '^https?:\/\/([a-zA-Z0-9\-]*)\.?checkmedia.org.*') do
      assert_nothing_raised do
        create_team subdomain: 'pender'
      end
    end
  end

  test "should create team with reserved subdomain from origin" do
    WebMock.stub_request(:head, 'http://pender.checkmedia.org').to_return(body: 'Pender', status: 200, headers: { 'X-Check-Web' => '1' })
    stub_config('checkdesk_client', '^https?:\/\/([a-zA-Z0-9\-]*)\.?checkmedia.org.*') do
      assert_nothing_raised do
        create_team subdomain: 'pender', origin: 'http://checkmedia.org'
      end
    end
  end

  test "should not create team with reserved subdomain if error is returned" do
    WebMock.stub_request(:head, 'http://pender.checkmedia.org').to_raise(StandardError)
    stub_config('checkdesk_client', '^https?:\/\/([a-zA-Z0-9\-]*)\.?checkmedia.org.*') do
      assert_raises ActiveRecord::RecordInvalid do
        create_team subdomain: 'pender', origin: 'http://checkmedia.org'
      end
    end
  end

  test "should have settings" do
    t = create_team
    assert_equal({}, t.settings)
    assert_nil t.setting(:foo)
    t.set_foo = 'bar'
    t.save!
    assert_equal 'bar', t.reload.get_foo

    assert_raise NoMethodError do
      t.something
    end
  end

  test "should set contact" do
    t = create_team
    assert_difference 'Contact.count' do
      t.contact = { location: 'Salvador', phone: '557133330101', web: 'http://meedan.com' }.to_json
    end
    assert_no_difference 'Contact.count' do
      t.contact = { location: 'Bahia' }.to_json
    end
    assert_equal 'Bahia', t.reload.contacts.first.location
  end

  test "should validate Slack webhook" do
    t = create_team
    assert_raises ActiveRecord::RecordInvalid do
      t.set_slack_webhook = 'http://meedan.com'
      t.save!
    end
    assert_nothing_raised do
      t.set_slack_webhook = 'https://hooks.slack.com/services/123456'
      t.save!
    end
  end
end
