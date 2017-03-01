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

  test "non members should not access private team" do
    u = create_user
    t = create_team
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu, role: 'owner'
    with_current_user_and_team(u, t) { Team.find_if_can(t.id) }
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Team.find_if_can(pt.id) }
    end
    with_current_user_and_team(pu, pt) { Team.find_if_can(pt.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Team.find_if_can(pt.id) }
    end
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(create_user, pt) { Team.find_if_can(pt) }
    end
  end

  test "should update and destroy team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    t.name = 'meedan'; t.save!
    t.reload
    assert_equal t.name, 'meedan'
    # update team as editor
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    with_current_user_and_team(u2, t) { t.name = 'meedan_mod'; t.save! }
    t.reload
    assert_equal t.name, 'meedan_mod'
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) { t.destroy }
    end
    Rails.cache.clear
    tu.role = 'journalist'; tu.save!
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) { t.save! }
    end
  end

  test "should not save team without name" do
    t = Team.new
    assert_not t.save
  end

  test "should not save team with invalid slugs" do
    assert_nothing_raised do
      create_team slug: "correct-الصهث-unicode"
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team slug: ''
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team slug: 'www'
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team slug: ''.rjust(64, 'a')
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team slug: ' some spaces '
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team slug: 'correct-الصهث-unicode'
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
      with_current_user_and_team(u, nil) { create_team }
    end
  end

  test "should not add user to team on team creation" do
    assert_no_difference 'TeamUser.count' do
      create_team
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
        with_current_user_and_team(u, nil) { create_team }
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
    t2 = nil
    with_current_user_and_team(u, nil) { t2 = create_team }
    assert_equal t2, u.reload.current_team
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

  test "should downcase slug" do
    t = create_team slug: 'NewsLab'
    assert_equal 'newslab', t.reload.slug
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    team = create_team
    perm_keys = ["read Team", "update Team", "destroy Team", "create Project", "create Account", "create TeamUser", "create User", "create Contact"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }
  end

  test "should have custom verification statuses" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Custom Status 2', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_nothing_raised do
      t.set_media_verification_statuses(value)
      t.save!
    end
    assert_equal 2, t.get_media_verification_statuses[:statuses].size
  end

  test "should not save invalid custom verification statuses" do
    t = create_team
    value = {
      default: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1', description: 'The meaning of this status' },
        { id: '2', label: 'Custom Status 2', description: 'The meaning of that status' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should not save invalid custom verification status" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1' },
        { id: '2', label: 'Custom Status 2', description: 'The meaning of that status' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should not create team with 'check' slug" do
    assert_raises ActiveRecord::RecordInvalid do
      create_team slug: 'check'
    end
  end

  test "should set verification statuses to settings" do
    t = create_team
    value = { label: 'Test', default: '', statuses: [{ id: 'first', label: 'Analyzing', description: 'Testing', style: 'bar' }] }
    t.media_verification_statuses = value
    t.source_verification_statuses = value
    t.save
    assert_equal value, t.get_media_verification_statuses
    assert_equal value, t.get_source_verification_statuses
  end

  test "should set slack_notifications_enabled" do
    t = create_team
    t.slack_notifications_enabled = true
    t.save
    assert t.get_slack_notifications_enabled
  end

  test "should set slack_webhook" do
    t = create_team
    t.slack_webhook = 'https://hooks.slack.com/services/123456'
    t.save
    assert_equal 'https://hooks.slack.com/services/123456', t.get_slack_webhook
  end

  test "should set slack_channel" do
    t = create_team
    t.slack_channel = 'my-channel'
    t.save
    assert_equal 'my-channel', t.get_slack_channel
  end

  test "should protect attributes from mass assignment" do
    raw_params = { name: 'My team', slug: 'my-team' }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Team.create(params)
    end
  end

  test "should destroy related items" do
    u = create_user
    t = create_team
    id = t.id
    t.description = 'update description'; t.save!
    tu = create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    a = create_account team: t
    c = create_contact team: t
    t.destroy
    assert_equal 0, Project.where(team_id: id).count
    assert_equal 0, TeamUser.where(team_id: id).count
    assert_equal 0, Account.where(team_id: id).count
    assert_equal 0, Contact.where(team_id: id).count
    assert_equal 0, ProjectMedia.where(project_id: p.id).count
  end

end
