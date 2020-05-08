require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
require 'sidekiq/testing'

class TeamTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
  end

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
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Team.find_if_can(pt.id) }
    end
    with_current_user_and_team(pu, pt) { Team.find_if_can(pt.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) { Team.find_if_can(pt.id) }
    end
    assert_raise CheckPermissions::AccessDenied do
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
    # update team as owner
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'owner'
    with_current_user_and_team(u2, t) { t.name = 'meedan_mod'; t.save! }
    t.reload
    assert_equal t.name, 'meedan_mod'
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) { t.destroy }
    end
    Rails.cache.clear
    u2 = User.find(u2.id)
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
    User.current = create_user
    t = create_team
    assert_equal 1, t.versions.size
    User.current = nil
  end

  test "should create version when team is updated" do
    User.current = create_user(is_admin: true)
    t = create_team
    t.logo = random_string
    t.save!
    assert_equal 2, t.versions.size
    User.current = nil
  end

  test "should have users" do
    t = create_team
    u1 = create_user
    u2 = create_user
    assert_equal [], t.users
    t.users << u1
    t.users << u2
    assert_equal [u1, u2].sort, t.users.sort
  end

  test "should have team_user" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t
    with_current_user_and_team(u, t) do
      assert_equal tu, t.team_user
    end
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
    assert_equal [tu1, tu2].sort, t.team_users.sort
    assert_equal [u1, u2].sort, t.users.sort
  end

  test "should get logo from callback" do
    t = create_team
    assert_nil t.logo_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil t.logo_callback(file)
    file = 'http://ca.ios.ba/files/others/rails.png'
    assert_nil t.logo_callback(file)
  end

  test "should add user to team on team creation" do
    u = create_user
    assert_difference 'TeamUser.count' do
      User.current = u
      Team.current = nil
      create_team
    end
  end

  test "should not add user to team on team creation" do
    assert_no_difference 'TeamUser.count' do
      create_team
    end
  end

  test "should be equivalent to set file or logo" do
    t = create_team logo: nil
    assert_match /team\.png$/, t.logo.url
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    f = Rack::Test::UploadedFile.new(path, 'image/png')
    t.file = f
    assert_match /rails\.png$/, t.logo.url
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

  test "should generate thumbnails for logo" do
    t = create_team logo: 'rails.png'
    assert_match /rails\.png$/, t.logo.path
    assert_match /thumbnail_rails\.png$/, t.logo.thumbnail.path
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

  test "should return number of projects" do
    t = create_team
    create_project team: t
    create_project team: t
    assert_equal 2, t.projects_count
  end

  test "should have a JSON version" do
    assert_kind_of Hash, create_team.as_json
  end

  test "should not send email when team is created" do
    u = create_user
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference 'TeamUser.count' do
        User.current = u
        create_team
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
    assert_equal({ max_number_of_members: 5 }, t.settings)
    assert_nil t.setting(:foo)
    t.set_foo = 'bar'
    t.save!
    assert_equal 'bar', t.reload.get_foo
    t.reset_foo
    t.save!
    assert_nil t.reload.get_foo
    t.settings = nil
    assert_nothing_raised do
      t.reset_foo
    end

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
    perm_keys = ["create TagText", "read Team", "update Team", "destroy Team", "empty Trash", "create Project", "create ProjectMedia", "create Account", "create TeamUser", "create User", "create Contact", "invite Members", "restore ProjectMedia", "update ProjectMedia"].sort

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

    # should get permissions info
    assert_not_nil t.permissions_info
  end

  test "should have custom verification statuses" do
    create_verification_status_stuff
    t = create_team
    assert (['verified', 'false', 'not_applicable'].sort == t.reload.final_media_statuses.sort || ['error', 'ready'].sort == t.reload.final_media_statuses.sort)
    value = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1', completed: '1', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Custom Status 2', completed: '0', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_nothing_raised do
      t.set_media_verification_statuses(value)
      t.save!
    end
    assert_equal ['1'].sort, t.reload.final_media_statuses.sort
    p = create_project team: t
    pm = create_project_media project: p
    s = pm.last_verification_status_obj.get_field('verification_status_status')
    assert_equal 'Custom Status 1', s.to_s
    assert_equal 2, t.get_media_verification_statuses[:statuses].size
    # Set verification status via media_verification_statuses
    assert_nothing_raised do
      t.add_media_verification_statuses = value
      t.save!
    end
  end

  test "should not save invalid custom verification statuses" do
    t = create_team
    value = {
      default: '1',
      active: '2',
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
      active: '2',
      statuses: [
        { id: '1', label: 'Custom Status 1' },
        { id: '2', label: 'Custom Status 2', description: 'The meaning of that status' },
        { id: '3', label: '', description: 'The meaning of that status' },
        { id: '', label: 'Custom Status 4', description: 'The meaning of that status' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should not save custom verification status if the default doesn't match any status id" do
    t = create_team
    variations = [
      {
        label: 'Field label',
        default: '10',
        active: '2',
        statuses: [
          { id: '1', label: 'Custom Status 1', description: 'The meaning of this status', style: 'red' },
          { id: '2', label: 'Custom Status 2', description: 'The meaning of that status', style: 'blue' }
        ]
      },
      {
        label: 'Field label',
        default: '1',
        active: '2',
        statuses: []
      }
    ]

    variations.each do |value|
      assert_raises ActiveRecord::RecordInvalid do
        t.set_media_verification_statuses(value)
        t.save!
      end
    end
  end

  test "should remove empty statuses before save custom verification statuses" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      active: '1',
      statuses: [
        { id: '1', label: 'Valid status', completed: '', description: 'The meaning of this status', style: 'red' },
        { id: '', label: '', completed: '', description: 'Status with empty id and label', style: 'blue' }
      ]
    }
    assert_nothing_raised do
      t.media_verification_statuses = value
      t.save!
    end
    assert_equal 1, t.get_media_verification_statuses[:statuses].size
  end

  test "should not save custom verification statuses if default or statuses is empty" do
    t = create_team
    value = {
      label: 'Field label',
      completed: '',
      default: '',
      active: '',
      statuses: []
    }
    assert_nothing_raised do
      t.media_verification_statuses = value
      t.save!
    end
    assert t.get_media_verification_statuses.nil?
  end

  test "should not save custom verification status if it is not a hash" do
    t = create_team
    value = 'invalid_status'
    assert_raises TypeError do
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should not change custom statuses that are already used in reports" do
    create_verification_status_stuff
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    s = pm.last_verification_status_obj
    value = {
      label: 'Field label',
      default: '1',
      active: '2',
      statuses: [
        { id: '1', label: 'Custom Status 1', completed: '', description: '', style: 'red' },
        { id: '2', label: 'Custom Status 2', completed: '', description: '', style: 'blue' }
      ]
    }
    t.set_limits_custom_statuses(true)
    t.save!
    t = Team.find(t.id)
    assert_raises ActiveRecord::RecordInvalid do
      t.set_media_verification_statuses(value)
      t.save!
    end
    assert_nothing_raised do
      value[:statuses] << { id: s.status, label: s.status, completed: '', description: '', style: 'blue' }
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should not create team with 'check' slug" do
    assert_raises ActiveRecord::RecordInvalid do
      create_team slug: 'check'
    end
  end

  test "should set background color and border color equal to color on verification statuses" do
    t = create_team
    value = {
      label: 'Test',
      statuses: [{
        id: 'first',
        label: 'Analyzing',
        description: 'Testing',
        style: {
          color: "blue"
        }}]
    }.with_indifferent_access
    t.media_verification_statuses = value
    t.save
    statuses = t.get_media_verification_statuses[:statuses].first
    %w(color backgroundColor borderColor).each do |k|
      assert_equal 'blue', statuses['style'][k]
    end
  end

  test "should not return backgroundColor and borderColor on AdminUI media custom statuses" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      active: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1', description: 'The meaning of this status', style: { color: 'red', backgroundColor: 'red', borderColor: 'red'} },
      ]
    }
    t.media_verification_statuses = value
    t.save

    status = t.get_media_verification_statuses[:statuses]
    assert_equal ['backgroundColor', 'borderColor', 'color'], status.first[:style].keys.sort

    status = t.media_verification_statuses[:statuses]
    assert_equal ['color'], status.first[:style].keys.sort
   end

  test "should return statuses as array after set statuses without it" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      active: '1'
    }
    t.media_verification_statuses = value

    assert_nil t.get_media_verification_statuses[:statuses]
    assert_equal [], t.media_verification_statuses[:statuses]
  end

   test "should not save statuses if default is present and statuses is missing" do
    t = create_team
    value = {
        label: 'Field label',
        default: '1',
        active: '1'
    }
    t.media_verification_statuses = value
    assert_raises NoMethodError do
      t.save!
    end

    assert Team.find(t.id).media_verification_statuses.nil?
  end

  test "should set verification statuses to settings" do
    t = create_team
    value = { label: 'Test', active: 'first', default: 'first', statuses: [{ id: 'first', label: 'Analyzing', description: 'Testing', style: 'bar' }]}.with_indifferent_access
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
    t.slack_channel = '#my-channel'
    t.save
    assert_equal '#my-channel', t.reload.get_slack_channel
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
    RequestStore.store[:disable_es_callbacks] = true
    t.destroy
    assert_equal 0, Project.where(team_id: id).count
    assert_equal 0, TeamUser.where(team_id: id).count
    assert_equal 0, Account.where(team_id: id).count
    assert_equal 0, Contact.where(team_id: id).count
    assert_equal 0, ProjectMedia.where(project_id: p.id).count
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should have search id" do
    t = create_team
    assert_not_nil t.search_id
  end

  test "should save valid slack_channel" do
    t = create_team
    value =  "#slack_channel"
    assert_nothing_raised do
      t.set_slack_channel(value)
      t.save!
    end
  end

  test "should not save slack_channel if is not valid" do
    t = create_team
    value = 'invalid_channel'
    assert_raises ActiveRecord::RecordInvalid do
      t.set_slack_channel(value)
      t.save!
    end
  end

  test "should be private by default" do
    Team.delete_all
    t = Team.new
    t.name = 'Test'
    t.slug = 'test'
    t.save!
    assert t.reload.private
  end

  test "should archive sources, projects and project medias when team is archived" do
    Sidekiq::Testing.inline! do
      t = create_team
      p1 = create_project
      p2 = create_project team: t
      s1 = create_source
      s2 = create_source team: t
      pm1 = create_project_media
      pm2 = create_project_media project: p2
      pm3 = create_project_media project: p2
      t.archived = true
      t.save!
      assert !pm1.reload.archived
      assert pm2.reload.archived
      assert pm3.reload.archived
      assert !p1.reload.archived
      assert p2.reload.archived
      assert !s1.reload.archived
      assert s2.reload.archived
    end
  end

  test "should archive sources, project and project medias in background when team is archived" do
    Sidekiq::Testing.fake! do
      t = create_team
      p = create_project team: t
      pm = create_project_media project: p
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      t.archived = true
      t.save!
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should not archive project and project medias in background if team is updated but archived flag does not change" do
    Sidekiq::Testing.fake! do
      t = create_team
      p = create_project team: t
      pm = create_project_media project: p
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      t.name = random_string
      t.save!
      assert_equal n, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should restore sources, project and project medias when team is restored" do
    Sidekiq::Testing.inline! do
      t = create_team
      p1 = create_project team: t
      p2 = create_project
      s1 = create_source team: t
      s2 = create_source
      pm1 = create_project_media
      pm2 = create_project_media project: p1
      pm3 = create_project_media project: p1
      t.archived = true
      t.save!
      assert !pm1.reload.archived
      assert pm2.reload.archived
      assert pm3.reload.archived
      assert p1.reload.archived
      assert !p2.reload.archived
      t = Team.find(t.id)
      t.archived = false
      t.save!
      assert !pm1.reload.archived
      assert !pm2.reload.archived
      assert !pm3.reload.archived
      assert !p1.reload.archived
      assert !p2.reload.archived
      assert !s1.reload.archived
      assert !s2.reload.archived
    end
  end

  test "should delete sources, project and project medias in background when team is deleted" do
    Sidekiq::Testing.fake! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'owner'
      p = create_project team: t
      pm = create_project_media project: p
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      with_current_user_and_team(u, t) do
       t.destroy_later
      end
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should delete sources, projects and project medias when team is deleted" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'owner'
      p1 = create_project
      p2 = create_project team: t
      s1 = create_source
      s2 = create_source team: t
      pm1 = create_project_media
      pm2 = create_project_media project: p2
      pm3 = create_project_media project: p2
      c = create_comment annotated: pm2
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        t.destroy_later
      end
      RequestStore.store[:disable_es_callbacks] = false
      assert_not_nil ProjectMedia.where(id: pm1.id).last
      assert_nil ProjectMedia.where(id: pm2.id).last
      assert_nil ProjectMedia.where(id: pm3.id).last
      assert_not_nil Project.where(id: p1.id).last
      assert_nil Project.where(id: p2.id).last
      assert_not_nil Source.where(id: s1.id).last
      assert_nil Source.where(id: s2.id).last
      assert_nil Comment.where(id: c.id).last
    end
  end

  test "should not delete team later if doesn't have permission" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        t.destroy_later
      end
    end
  end

  test "should empty trash in background" do
    Sidekiq::Testing.fake! do
      t = create_team
      p = create_project team: t
      3.times { create_project_media(project: p, archived: true) }
      u = create_user
      create_team_user user: u, team: t, role: 'owner'
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      assert_equal 0, p.reload.project_medias.where(inactive: true).count
      with_current_user_and_team(u, t) do
       t.empty_trash = 1
       assert_equal 3, p.reload.project_medias.where(inactive: true).count
      end
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should empty trash if has permissions" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'owner'
      p = create_project team: t
      3.times { pm = create_project_media(project: p); pm.archived = true; pm.save! }
      2.times { create_project_media(project: p) }
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        assert_nothing_raised do
          assert_difference 'ProjectMedia.count', -3 do
            t.empty_trash = 1
          end
        end
      end
      RequestStore.store[:disable_es_callbacks] = false
    end
  end

  test "should not empty trash if has no permissions" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'contributor'
      p = create_project team: t
      3.times { pm = create_project_media(project: p); pm.archived = true; pm.save! }
      2.times { create_project_media(project: p) }
      with_current_user_and_team(u, t) do
        assert_raises RuntimeError do
          assert_no_difference 'ProjectMedia.count' do
            t.empty_trash = 1
          end
        end
      end
    end
  end

  test "should get trash size" do
    Sidekiq::Testing.inline!
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    pm1.archived = true
    pm1.save!
    pm2.archived = true
    pm2.save!
    size = t.reload.trash_size
    assert_equal 2, size[:project_media]
  end

  test "should get search id" do
    t = create_team
    assert_kind_of CheckSearch, t.check_search_team
  end

  test "should get GraphQL id" do
    t = create_team
    assert_kind_of String, t.graphql_id
    assert_kind_of String, t.team_graphql_id
    assert_equal t.graphql_id, t.team_graphql_id
  end

  test "should not set custom statuses if limited" do
    t = create_team
    t.set_limits_custom_statuses(false)
    t.save!
    t = Team.find(t.id)
    value = {
      label: 'Field label',
      default: '1',
      active: '2',
      statuses: [
        { id: '1', label: 'Custom Status 1', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Custom Status 2', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should return the json schema url" do
    t = create_team
    fields = {
      'media_verification_statuses': 'statuses',
      'source_verification_statuses': 'statuses',
      'limits': 'limits'
    }

    fields.each do |field, filename|
      assert_equal URI.join(CONFIG['checkdesk_base_url'], "/#{filename}.json"), t.json_schema_url(field.to_s)
    end
  end

  test "should have public team id" do
    t = create_team
    assert_kind_of String, t.public_team_id
  end

  test "should have public team alias" do
    t = create_team
    assert_equal t, t.public_team
  end

  test "should duplicate a team and copy team users and contacts" do
    team = create_team name: 'Team A', logo: 'rails.png'

    u1 = create_user
    u2 = create_user
    create_team_user team: team, user: u1, role: 'owner', status: 'member'
    create_team_user team: team, user: u2, role: 'editor', status: 'invited'
    create_contact team: team

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 2, TeamUser.where(team_id: copy.id).count
    assert_equal 1, Contact.where(team_id: copy.id).count

    # team attributes
    assert_equal "#{team.slug}-copy-1", copy.slug
    %w(name archived private description).each do |att|
      assert_equal team.send(att), copy.send(att)
    end

    # team users
    assert_equal team.team_users.map { |tu| [tu.user.id, tu.role, tu.status] }, copy.team_users.map { |tu| [tu.user.id, tu.role, tu.status] }

    # contacts
    assert_equal team.contacts.map(&:web), copy.contacts.map(&:web)

    assert_difference 'Team.count', -1 do
      copy.destroy
    end
    assert_equal 2, TeamUser.where(team_id: team.id).count
    assert_equal 1, Contact.where(team_id: team.id).count
  end

  test "should duplicate a team and copy sources and project medias" do
    team = create_team name: 'Team A', logo: 'rails.png'
    u = create_user
    project = create_project team: team, user: u
    source = create_source user: u
    source.team = team; source.save
    account = create_account user: u, team: team, source: source
    create_project_source user: u, team: team, project: project, source: source

    media = create_media account: account, user: u
    pm1 = create_project_media user: u, team: team, project: project, media: media

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    assert_equal 1, Source.where(team_id: copy.id).count
    assert_equal 1, project.project_medias.count
    assert_equal 2, project.project_sources.count

    copy_p = copy.projects.find_by_title(project.title)

    # sources
    assert_equal team.sources.map { |s| [s.user.id, s.slogan, s.file.path ] }, copy.sources.map { |s| [s.user.id, s.slogan, s.file.path ] }

    # project sources
    assert_not_equal project.project_sources.map(&:source).sort, copy_p.project_sources.map(&:source).sort

    # project medias
    assert_equal project.project_medias.map(&:media).sort, copy_p.project_medias.map(&:media).sort

    assert_difference 'Team.count', -1 do
      copy.destroy
    end
    assert_equal 1, Source.where(team_id: team.id).count
    assert_equal 1, project.project_medias.count
    assert_equal 2, project.project_sources.count
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should duplicate a team and annotations" do
    team = create_team name: 'Team A', logo: 'rails.png'

    project = create_project team: team, title: 'Project'
    u = create_user
    pm = create_project_media user: u, team: team, project: project

    create_comment annotated: pm
    create_tag annotated: pm
    create_flag annotated: pm

    at = create_annotation_type annotation_type: 'response'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'

    task = create_task annotated: pm, annotator: u
    task.response = { annotation_type: 'response', set_fields: { response: 'Test' }.to_json }.to_json; task.save!
    original_annotations_count = pm.annotations.size

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)

    copy_p = copy.projects.find_by_title('Project')
    copy_pm = copy_p.project_medias.first

    assert_equal ["comment", "flag", "tag", "task"], copy_pm.annotations.map(&:annotation_type).sort
    assert_equal 1, copy_pm.annotations.where(annotation_type: 'task').count
    copy_task = copy_pm.annotations.where(annotation_type: 'task').last
    assert_equal 1, Annotation.where(annotated_id: copy_task, annotation_type: 'response').count
    assert_equal original_annotations_count, copy_pm.annotations.size

    assert_difference 'Team.count', -1 do
      copy.destroy
    end
    assert_equal original_annotations_count, ProjectMedia.find(pm.id).annotations.size
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should generate slug for copy based on original" do
    team1 = create_team slug: 'team-a'
    team2 = create_team slug: 'team-a-copy-1'
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team1)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 'team-a-copy-2', copy.slug
  end

  test "should copy versions on team duplication" do
    t = create_team
    u = create_user
    u.is_admin = true;u.save
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p1 = create_project team: t
      pm = create_project_media user: u, team: t, project: p1
      p2 = create_project team: t
      pm.project_id = p2.id; pm.save!
      RequestStore.store[:disable_es_callbacks] = true
      copy = Team.duplicate(t, u)
      assert copy.is_a?(Team)
      RequestStore.store[:disable_es_callbacks] = false
    end
    User.current = nil
  end

  test "should copy versions on team duplication and destroy it when embed has previous version" do
    [DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldType, DynamicAnnotation::FieldInstance].each{ |klass| klass.delete_all }
    create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
    t = create_team
    u = create_user
    u.is_admin = true;u.save
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p = create_project team: t
      pm1 = create_project_media user: u, team: t, project: p
      pm2 = create_project_media user: u, team: t, project: p
      e = create_metadata annotated: pm1, title: 'Foo', annotator: u
      e = Dynamic.find(e.id)
      e.title = 'bar'; e.annotated = pm2; e.save!
      RequestStore.store[:disable_es_callbacks] = true
      copy = Team.duplicate(t, u)

      copy_pm1 = copy.projects.first.project_medias.first
      copy_pm2 = copy.projects.first.project_medias.last
      copy_e = copy_pm2.annotations('metadata').last.load.get_field('metadata_value')
      v = copy_e.versions.last
      assert_equal copy_e.id.to_s, v.item_id
      assert_equal [copy_e.id, copy_pm2.id], [v.get_object['id'], v.associated_id]
      obj_after = JSON.parse v.object_after
      assert_equal [copy_e.id, copy_pm2.id], [obj_after['id'], v.associated_id]
      assert copy.destroy!
      RequestStore.store[:disable_es_callbacks] = false
    end
    User.current = nil
  end

  test "should generate slug with 63 maximum chars" do
    team = create_team slug: 'lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-morbi-at'
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 'lorem-ipsumsit-amet-consectetur-adipiscing-elit-morbi-at-copy-1', copy.slug
  end

  test "should not copy invalid statuses" do
    team = create_team
    value = { 'default' => '1', 'active' => '1' }
    team.set_media_verification_statuses(value)
    assert_raises NoMethodError do
      assert !team.valid?
    end
    team.save(validate: false)
    assert_equal value, team.get_media_verification_statuses
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert copy.errors[:statuses].blank?
    assert_equal team.get_media_verification_statuses, copy.get_media_verification_statuses
  end

  test "should not notify slack if is being copied" do
    create_slack_bot
    team = create_team
    user = create_user
    create_team_user team: team, user: user, role: 'owner'
    project = create_project team: team, title: 'Project'
    pm = create_project_media project: project
    source = create_source user: user
    source.team = team; source.save

    assert !Bot::Slack.default.nil?
    Bot::Slack.any_instance.stubs(:notify_slack).never
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert copy.valid?
    Bot::Slack.any_instance.unstub(:notify_slack)
  end

  test "should duplicate team with duplicated source" do
    team = create_team
    user = create_user
    source = create_source user: user, team: team
    duplicated_source = source.dup
    duplicated_source.save(validate: false)

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert Team.exists?(copy.id)
  end

  test "should copy comment image" do
    team = create_team name: 'Team A'

    project = create_project team: team, title: 'Project'
    u = create_user
    pm = create_project_media user: u, team: team, project: project
    c = create_comment annotated: pm, file: 'rails.png'

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false

    copy_p = copy.projects.find_by_title('Project')
    copy_pm = copy_p.project_medias.first
    copy_comment = copy_pm.get_annotations('comment').first.load
    assert_match /^http/, copy_comment.file.file.public_url
  end

  test "should skip validation on team with big image" do
    team = create_team
    user = create_user
    pm = create_project_media team: team, project: create_project(team: team)
    c = create_comment annotated: pm
    File.open(File.join(Rails.root, 'test', 'data', 'rails-photo.jpg')) do |f|
      c.file = f
    end
    c.save(validate: false)

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert copy.valid?
  end

  test "should generate new token on duplication" do
    team = create_team
    project = create_project team: team
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    copy_p = copy.projects.find_by_title(project.title)
    assert_not_equal project.token, copy_p.token
  end

  test "should duplicate a team when project is archived" do
    team = create_team name: 'Team A', logo: 'rails.png'
    project = create_project team: team

    pm1 = create_project_media team: team, project: project
    project.archived = true; project.save!

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false

    copy_p = copy.projects.find_by_title(project.title)
    assert_equal project.project_medias.map(&:media).sort, copy_p.project_medias.map(&:media).sort
  end

  test "should duplicate a team with sources and projects when team is archived" do
    team = create_team name: 'Team A', logo: 'rails.png'
    project = create_project team: team

    source = create_source
    source.team = team; source.save

    team.archived = true; team.save!

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 1, Project.where(team_id: copy.id).count
    assert_equal 1, Source.where(team_id: copy.id).count
  end

  test "should reset current team when team is deleted" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    u.current_team_id = t.id
    u.save!
    assert_not_nil u.reload.current_team_id
    t.destroy
    assert_nil u.reload.current_team_id
  end

  test "should notify Airbrake when duplication raises error" do
    team = create_team
    RequestStore.store[:disable_es_callbacks] = true
    Airbrake.stubs(:configured?).returns(true)
    Airbrake.stubs(:notify).once
    Team.any_instance.stubs(:save).with(validate: false).raises(RuntimeError)

    assert_nil Team.duplicate(team)
    Airbrake.unstub(:configured?)
    Airbrake.unstub(:notify)
    Team.any_instance.unstub(:save)
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should not save custom statuses if active and default values are not set" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1', completed: '', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Custom Status 2', completed: '', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t = Team.find(t.id)
      t.set_media_verification_statuses(value)
      t.save!
    end
    value = {
      label: 'Field label',
      active: '1',
      statuses: [
        { id: '1', label: 'Custom Status 1', completed: '', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Custom Status 2', completed: '', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t = Team.find(t.id)
      t.set_media_verification_statuses(value)
      t.save!
    end
    value = {
      label: 'Field label',
      default: '1',
      active: '2',
      statuses: [
        { id: '1', label: 'Custom Status 1', completed: '', description: 'The meaning of this status', style: 'red' },
        { id: '2', label: 'Custom Status 2', completed: '', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_nothing_raised do
      t = Team.find(t.id)
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should not save custom statuses with invalid identifiers" do
    t = create_team
    value = {
      label: 'Field label',
      default: 'ok',
      active: 'ok',
      statuses: [
        { id: 'ok', label: 'Custom Status 1', completed: '', description: 'The meaning of this status', style: 'red' },
        { id: 'foo bar', label: 'Custom Status 2', completed: '', description: 'The meaning of that status', style: 'blue' }
      ]
    }
    assert_raises ActiveRecord::RecordInvalid do
      t = Team.find(t.id)
      t.set_media_verification_statuses(value)
      t.save!
    end
    value = {
      label: 'Field label',
      default: 'ok',
      active: 'ok',
      statuses: [
        { id: 'ok', label: 'Custom Status 1', completed: '', description: 'The meaning of this status', style: 'red' },
        { id: 'foo-bar', label: 'Custom Status 2', completed: '', description: 'The meaning of that status', style: 'blue' }
      ]
    }
  end

  test "should get owners based on user role" do
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'owner'
    create_team_user team: t, user: u2, role: 'editor'
    assert_equal [u.id], t.owners('owner').map(&:id)
    assert_equal [u2.id], t.owners('editor').map(&:id)
    assert_equal [u.id, u2.id].sort, t.owners(['owner', 'editor']).map(&:id).sort
  end

  test "should get uniq owners by team_users relation" do
    t = create_team
    other_t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    create_team_user team: other_t, user: u, role: 'owner'
    assert_equal [u.id], t.owners('owner').map(&:id)
  end

  test "should get used tags" do
    team = create_team
    project = create_project team: team
    u = create_user
    pm1 = create_project_media user: u, team: team, project: project
    create_tag annotated: pm1, tag: 'tag1'
    create_tag annotated: pm1, tag: 'tag2'
    pm2 = create_project_media user: u, team: team, project: project
    create_tag annotated: pm2, tag: 'tag2'
    create_tag annotated: pm2, tag: 'tag3'
    assert_equal ['tag1', 'tag2', 'tag3'].sort, team.used_tags.sort
  end

  test "should destroy a duplicated team with project media" do
    team = create_team name: 'Team A', logo: 'rails.png'
    u = create_user
    project = create_project team: team, user: u
    create_team_user team: team, user: u, role: 'owner'
    pm = nil
    with_current_user_and_team(u, team) do
      pm = create_project_media user: u, team: team, project: project
      pm.archived = true ; pm.save
    end
    Team.current = User.current = nil
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    copy_p = copy.projects.find_by_title(project.title)
    copy_pm = copy_p.project_medias.first
    assert_equal pm.versions.map(&:event_type).sort, copy_pm.versions.map(&:event_type).sort
    assert_equal pm.versions.count, copy_pm.versions.count
    assert_equal pm.get_versions_log.count, copy_pm.get_versions_log.count

    assert_nothing_raised do
      copy.destroy
    end
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should duplicate a team and copy relationships and versions" do
    team = create_team
    u = create_user is_admin: true
    create_team_user team: team, user: u, role: 'owner'
    project = create_project team: team, user: u
    RequestStore.store[:disable_es_callbacks] = true
    with_current_user_and_team(u, team) do
      pm1 = create_project_media user: u, team: team, project: project
      pm2 = create_project_media user: u, team: team, project: project
      create_relationship source_id: pm1.id, target_id: pm2.id

      assert_equal 1, Relationship.count
      assert_equal [1, 0, 0, 1], [pm1.source_relationships.count, pm1.target_relationships.count, pm2.source_relationships.count, pm2.target_relationships.count]

      version =  pm1.get_versions_log.first
      changes = version.get_object_changes
      assert_equal [[nil, pm1.id], [nil, pm2.id], [nil, pm1.source_relationships.first.id]], [changes['source_id'], changes['target_id'], changes['id']]
      assert_equal pm2.full_url, JSON.parse(version.meta)['target']['url']

      copy = Team.duplicate(team)
      copy_p = copy.projects.find_by_title(project.title)
      copy_pm1 = copy_p.project_medias.where(media_id: pm1.media.id).first
      copy_pm2 = copy_p.project_medias.where(media_id: pm2.media.id).first

      assert_equal 2, Relationship.count
      assert_equal [1, 0, 0, 1], [copy_pm1.source_relationships.count, copy_pm1.target_relationships.count, copy_pm2.source_relationships.count, copy_pm2.target_relationships.count]
      version =  copy_pm1.reload.get_versions_log[2].reload
      changes = version.get_object_changes
      assert_equal [[nil, copy_pm1.id], [nil, copy_pm2.id], [nil, copy_pm1.source_relationships.first.id]], [changes['source_id'], changes['target_id'], changes['id']]
      assert_equal copy_pm2.full_url, JSON.parse(version.meta)['target']['url']
    end
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should be related to bots" do
    t = create_team
    tb1 = create_team_bot set_approved: true
    tb2 = create_team_bot team_author_id: t.id
    tbi = create_team_bot_installation team_id: t.id, user_id: tb1.id
    assert_equal 2, t.reload.team_bot_installations.count
    assert_equal [tb1, tb2].sort, t.reload.team_bots.sort
    assert_equal [tb2], t.team_bots_created
    t.destroy
    assert_nil TeamBotInstallation.where(id: tbi.id).last
    assert_nil BotUser.where(id: tb2.id).last
    assert_not_nil BotUser.where(id: tb1.id).last
  end

  test "should get invited mails" do
    t = create_team
    u = create_user
    Team.stubs(:current).returns(t)
    members = [{role: 'contributor', email: 'test1@local.com'}, {role: 'journalist', email: 'test2@local.com'}]
    User.send_user_invitation(members)
    assert_equal ['test1@local.com', 'test2@local.com'].sort, t.invited_mails.sort
    u = User.where(email: 'test1@local.com').last
    User.accept_team_invitation(u.read_attribute(:raw_invitation_token), t.slug)
    assert_equal ['test2@local.com'], t.invited_mails
    Team.unstub(:current)
  end

  test "should get suggested tags" do
    t = create_team
    create_tag_text text: 'foo', team_id: t.id, teamwide: true
    create_tag_text text: 'bar', team_id: t.id, teamwide: true
    create_tag_text text: 'test', team_id: t.id
    assert_equal 'bar,foo', t.reload.get_suggested_tags
  end

  test "should destroy team tasks when team is destroyed" do
    t = create_team
    2.times { create_team_task(team_id: t.id) }
    assert_difference 'TeamTask.count', -2 do
      t.destroy!
    end
  end

  test "should duplicate a team and copy team tasks" do
    team = create_team name: 'Team A', logo: 'rails.png'
    create_team_task team_id: team.id, label: 'Foo'
    create_team_task team_id: team.id, label: 'Bar'

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 2, TeamTask.where(team_id: copy.id).count

    assert_equal team.team_tasks.map(&:label).sort, copy.team_tasks.map(&:label).sort

    assert_difference 'Team.count', -1 do
      copy.destroy
    end
    assert_equal 2, TeamTask.where(team_id: team.id).count
  end

  test "should have teams with the same slug" do
    create_team slug: 'testduplicatedslug'
    t = create_team
    assert_raises ActiveRecord::RecordNotUnique do
      t.update_column :slug, 'testduplicatedslug'
    end
  end

  test "should refresh permissions when loading a team" do
    u1 = create_user
    t1 = create_team
    u2 = create_user
    t2 = create_team
    create_team_user user: u1, team: t1, status: 'member', role: 'owner'
    create_team_user user: u2, team: t1, status: 'member', role: 'annotator'
    sleep 1
    create_team_user user: u1, team: t2, status: 'member', role: 'annotator'
    create_team_user user: u2, team: t2, status: 'member', role: 'owner'

    assert_equal 2, t1.members_count
    assert_equal 2, t2.members_count

    User.current = u1
    Team.current = t2
    assert_equal [2, 1], u1.team_users.order('id ASC').collect{ |x| x.team.members_count }
    Team.current = t1
    assert_equal [2, 1], u1.team_users.order('id ASC').collect{ |x| x.team.members_count }

    User.current = u2
    Team.current = t1
    assert_equal [1, 2], u2.team_users.order('id ASC').collect{ |x| x.team.members_count }
    Team.current = t2
    assert_equal [1, 2], u2.team_users.order('id ASC').collect{ |x| x.team.members_count }
    Team.current = nil
  end

  test "should get dynamic fields schema" do
    create_flag_annotation_type
    t = create_team slug: 'team'
    p = create_project team: t
    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language
    pm1 = create_project_media disable_es_callbacks: false, project: p
    create_dynamic_annotation annotation_type: att, annotated: pm1, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
    pm2 = create_project_media disable_es_callbacks: false, project: p
    create_dynamic_annotation annotation_type: att, annotated: pm2, set_fields: { language: 'pt' }.to_json, disable_es_callbacks: false
    create_flag annotated: pm2, disable_es_callbacks: false
    schema = t.dynamic_search_fields_json_schema
    assert_equal ['en', 'pt', 'und'], schema[:properties]['language'][:items][:enum].sort
    assert_not_nil schema[:properties]['flag_name']
    assert_not_nil schema[:properties]['flag_value']
  end

  test "should return search object" do
    t = create_team
    assert_kind_of CheckSearch, t.search
  end

  test "should set max number of members" do
    t = create_team
    assert_equal 5, t.get_max_number_of_members
    t.max_number_of_members = 23
    t.save!
    assert_equal 23, t.reload.get_max_number_of_members
    assert_equal 23, t.reload.max_number_of_members
  end

  test "should not crash when emptying trash that has task comments" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'owner'
      p = create_project team: t
      pm = create_project_media project: p
      tk = create_task annotated: pm
      create_comment annotated: tk
      pm.archived = true
      pm.save!
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        assert_nothing_raised do
          t.empty_trash = 1
        end
      end
      RequestStore.store[:disable_es_callbacks] = false
    end
  end

  test "should upload image to S3" do
    t = create_team
    assert_match /#{Regexp.escape(CONFIG['storage']['asset_host'])}/, t.avatar
  end

  test "should be able to create partitions in parallel" do
    threads = []
    threads << Thread.start do
      create_team
    end
    threads << Thread.start do
      create_team
    end
    threads.map(&:join)
  end

  test "should return rules as JSON schema" do
    assert_not_nil create_team.rules_json_schema
  end

  test "should match keyword with rule" do
    t = create_team
    p = create_project team: t
    ['^&$#(hospital', 'hospital?!', 'Hospital!!!'].each do |text|
      pm = create_project_media quote: text, project: p, smooch_message: { 'text' => text }
      assert t.contains_keyword(pm, nil, 'hospital', nil)
    end
  end

  test "should match rule based on status" do
    create_verification_status_stuff
    create_task_status_stuff(false)
    setup_elasticsearch
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "status_is",
          "rule_value": "in_progress"
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p0, disable_es_callbacks: false
    s = pm1.last_status_obj
    s.status = 'in_progress'
    s.save!
    sleep 5
    result = MediaSearch.find(get_es_id(pm1))
    assert_equal [p1.id], result.project_id
    pm2 = create_project_media project: p0, disable_es_callbacks: false
    assert_equal p1.id, pm1.reload.project_id
    assert_equal p0.id, pm2.reload.project_id
  end

  test "should match rule based on tag" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "tagged_as",
          "rule_value": "foo"
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "tagged_as",
          "rule_value": "bar"
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p2.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p0
    create_tag tag: 'foo', annotated: pm1
    pm2 = create_project_media project: p0
    create_tag tag: 'bar', annotated: pm2
    pm3 = create_project_media project: p0
    create_tag tag: 'test', annotated: pm2
    assert_equal p1.id, pm1.reload.project_id
    assert_equal p2.id, pm2.reload.project_id
    assert_equal p0.id, pm3.reload.project_id
  end

  test "should match rule based on item type" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'contributor'
    p0 = create_project team: t
    p1 = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t
    p4 = create_project team: t
    rules = []
    { 'claim' => p1, 'uploadedvideo' => p2, 'uploadedimage' => p3, 'link' => p4 }.each do |type, p|
      rules << {
        "name": random_string,
        "project_ids": "",
        "rules": [
          {
            "rule_definition": "type_is",
            "rule_value": type
          }
        ],
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p.id.to_s
          }
        ]
      }
    end
    t.rules = rules.to_json
    t.save!
    s = create_source
    c = create_claim_media account: create_valid_account
    c.account.sources << s
    ps1 = create_project_source project: p0, source: s
    ps2 = create_project_source project: p1, source: s
    pm1 = pm2 = pm3 = pm4 = nil
    Airbrake.stubs(:configured?).returns(true)
    Airbrake.stubs(:notify).raises(StandardError)
    with_current_user_and_team(u, t) do
      pm1 = create_project_media media: c, project: p0
      pm2 = create_project_media media: create_uploaded_video, project: p0
      pm3 = create_project_media media: create_uploaded_image, project: p0
      pm4 = create_project_media media: create_link, project: p0
    end
    Airbrake.unstub(:configured?)
    Airbrake.unstub(:notify)
    assert_equal p1.id, pm1.reload.project_id
    assert_equal p2.id, pm2.reload.project_id
    assert_equal p3.id, pm3.reload.project_id
    assert_equal p4.id, pm4.reload.project_id
  end

  test "should return number of items in trash and outside trash" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    create_project_media project: p1
    create_project_media project: p1
    create_project_media project: p1, archived: 1
    create_project_media project: p2
    create_project_media project: p2
    create_project_media project: p2, archived: 1
    create_project_media
    create_project_media
    create_project_media archived: 1
    assert_equal 2, t.reload.trash_count
    assert_equal 4, t.reload.medias_count
  end

  test "should be copied to another project as a result of a rule" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "title_matches_regexp",
          "rule_value": "^start_with_title"
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    m = create_claim_media quote: 'start_with_title match title'
    create_project_media project: p0, media: m, smooch_message: { 'text' => 'start_with_request match request' }
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 1, Project.find(p1.id).project_media_projects.count
  end

  test "should match rule by title" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "title_contains_keyword",
          "rule_value": "test"
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","title":"this is a test","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    create_project_media project: p0, media: nil, url: url
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 1, Project.find(p1.id).project_media_projects.count
  end

  test "should match rule by number of words and type" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "has_less_than_x_words",
          "rule_value": "3"
        },
        {
          "rule_definition": "type_is",
          "rule_value": "claim"
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    m = create_claim_media quote: 'test'
    create_project_media project: p0, media: m, smooch_message: { 'text' => 'test' }
    m = create_link
    create_project_media project: p0, media: m, smooch_message: { 'text' => 'test' }
    assert_equal 2, Project.find(p0.id).project_media_projects.count
    assert_equal 1, Project.find(p1.id).project_media_projects.count
  end

  test "should match rule by number of words" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "has_less_than_x_words",
          "rule_value": "3"
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","title":"this is a test","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    create_project_media project: p0, media: nil, url: url, smooch_message: { 'text' => 'test' }
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 1, Project.find(p1.id).project_media_projects.count
  end

  test "should match with regexp" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    p2 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "title_matches_regexp",
          "rule_value": "^start_with_title"
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "request_matches_regexp",
          "rule_value": "^start_with_request"
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p2.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media project: p0, quote: 'start_with_title match title'
    assert_equal p1.id, pm1.reload.project_id
    pm2 = create_project_media project: p0, quote: 'title', smooch_message: { 'text' => 'start_with_request match request' }
    assert_equal p2.id, pm2.reload.project_id
    pm3 = create_project_media project: p0, quote: 'did not match', smooch_message: { 'text' => 'did not match' }
    assert_equal p0.id, pm3.reload.project_id
  end

  test "should skip permission when applying action" do
    t = create_team
    p = create_project team: t
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: nil, set_events: [], set_request_url: "#{CONFIG['checkdesk_base_url_private']}/api/bots/smooch"
    create_team_bot_installation user_id: b.id, settings: nil, team_id: t.id
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "has_less_than_x_words",
          "rule_value": "3"
        }
      ],
      "actions": [
        {
          "action_definition": "send_to_trash",
        }
      ]
    }
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "has_less_than_x_words",
          "rule_value": "4"
        }
      ],
      "actions": [
        {
          "action_definition": "send_to_trash",
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","title":"this is a test","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_nothing_raised do
      with_current_user_and_team(b, t) do
        create_project_media project: p, media: nil, url: url, smooch_message: { 'text' => 'test' }
      end
    end
  end

  test "should save valid languages" do
    t = create_team
    value = ["en", "ar", "fr"]
    assert_nothing_raised do
      t.set_languages(value)
      t.save!
    end
  end

  test "should not save invalid languages" do
    t = create_team
    value = "en"
    assert_raises ActiveRecord::RecordInvalid do
      t.set_languages(value)
      t.save!
    end
  end

  test "should get languages" do
    t = create_team
    assert_equal nil, t.get_languages
    t.settings = {:languages => ['ar', 'en']}; t.save!
    assert_equal ['ar', 'en'], t.get_languages
  end

  test "should match rule and trigger action to send message to user" do
    setup_smooch_bot
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "status_is",
          "rule_value": "in_progress"
        }
      ],
      "actions": [
        {
          "action_definition": "send_message_to_user",
          "action_value": random_string
        }
      ]
    }
    @team.rules = rules.to_json
    @team.save!
    messages = [
      {
        '_id': random_string,
        authorId: random_string,
        type: 'text',
        text: 'foo bar'
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert Bot::Smooch.run(payload)
    Bot::Smooch.expects(:send_message_to_user).once
    pm = ProjectMedia.last
    s = pm.last_status_obj
    s.status = 'in_progress'
    s.save!
    Bot::Smooch.unstub(:send_message_to_user)
  end

  test "should support emojis in regexp rule" do
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = [{
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "title_matches_regexp",
          "rule_value": "/(\\u00a9|\\u00ae|[\\u2000-\\u3300]|\\ud83c[\\ud000-\\udfff]|\\ud83d[\\ud000-\\udfff]|\\ud83e[\\ud000-\\udfff])/gmi"
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }]
    t.rules = rules.to_json
    assert_raises ActiveRecord::RecordInvalid do
      t.save!
    end
    rules = [{
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "title_matches_regexp",
          "rule_value": "[\\u{1F300}-\\u{1F5FF}|\\u{1F1E6}-\\u{1F1FF}|\\u{2700}-\\u{27BF}|\\u{1F900}-\\u{1F9FF}|\\u{1F600}-\\u{1F64F}|\\u{1F680}-\\u{1F6FF}|\\u{2600}-\\u{26FF}]"
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }]
    t.rules = rules.to_json
    assert_nothing_raised do
      t.save!
    end
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    m = create_claim_media quote: '😊'
    create_project_media project: p0, media: m, smooch_message: { 'text' => '😊' }
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 1, Project.find(p1.id).project_media_projects.count
  end

  test "should not crash if rules throw exception" do
    Team.any_instance.stubs(:apply_rules).raises(RuntimeError)
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    create_project_media project: p0
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    Team.any_instance.unstub(:apply_rules)
  end

  test "should not crash if text for keyword rule is nil" do
    t = create_team
    assert_nothing_raised do
      assert !t.text_contains_keyword(nil, 'foo,bar')
    end
  end

  test "should relate items with similar titles through rules" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}|#{CONFIG['storage']['endpoint']}/
      t = create_team
      p = create_project team: t
      rules = []
      rules << {
        "name": random_string,
        "project_ids": "",
        "rules": [
          {
            "rule_definition": "item_titles_are_similar",
            "rule_value": "70"
          }
        ],
        "actions": [
          {
            "action_definition": "relate_similar_items",
            "action_value": ""
          }
        ]
      }
      t.rules = rules.to_json
      t.save!
      WebMock.stub_request(:get, 'http://alegre/text/similarity/')
        .with(body: { text: 'This is only a test', context: { team_id: t.id, field: 'title' }, threshold: 0.7 }.to_json)
        .to_return(status: 200, body: { result: [] }.to_json)
      pm1 = create_project_media project: p, quote: 'This is only a test'
      WebMock.stub_request(:get, 'http://alegre/text/similarity/')
        .with(body: { text: 'This is just a test', context: { team_id: t.id, field: 'title' }, threshold: 0.7 }.to_json)
        .to_return(status: 200, body: { result: [{ '_source' => { context: { project_media_id: pm1.id } } }] }.to_json)
      pm2 = create_project_media project: p, quote: 'This is just a test'
      assert_not_nil Relationship.where(source_id: pm1.id, target_id: pm2.id).last
    end
  end

  test "should relate similar images through rules" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}|#{CONFIG['storage']['endpoint']}/
      t = create_team
      p = create_project team: t
      rules = []
      rules << {
        "name": random_string,
        "project_ids": "",
        "rules": [
          {
            "rule_definition": "item_images_are_similar",
            "rule_value": "70"
          }
        ],
        "actions": [
          {
            "action_definition": "relate_similar_items",
            "action_value": ""
          }
        ]
      }
      t.rules = rules.to_json
      t.save!
      body = { context: { team_id: t.id }, threshold: 0.7 }
      WebMock.stub_request(:get, 'http://alegre/image/similarity/')
        .with(body: WebMock.hash_including(body))
        .to_return(status: 200, body: { result: [] }.to_json)
      pm1 = create_project_media project: p, media: create_uploaded_image
      WebMock.stub_request(:get, 'http://alegre/image/similarity/')
        .with(body: WebMock.hash_including(body))
        .to_return(status: 200, body: { result: [{ context: { project_media_id: pm1.id } }] }.to_json)
      pm2 = create_project_media project: p, media: create_uploaded_image
      assert_not_nil Relationship.where(source_id: pm1.id, target_id: pm2.id).last
    end
  end

  test "should list custom statuses as options for rule" do
    create_verification_status_stuff(false)
    t = create_team
    value = {
      label: 'Status',
      default: 'stop',
      active: 'done',
      statuses: [
        { id: 'stop', label: 'Stopped', completed: '', description: 'Not started yet', style: { backgroundColor: '#a00' } },
        { id: 'done', label: 'Done!', completed: '', description: 'Nothing left to be done here', style: { backgroundColor: '#fc3' } }
      ]
    }
    t.send :set_media_verification_statuses, value
    t.save!
    assert_match /.*stop.*done.*/, t.reload.rules_json_schema
  end

  test "should not check for similar items if object is null" do
    t = create_team
    pm = create_project_media team: t
    assert !t.items_are_similar('image', pm, pm, 50, random_string)
  end

  test "should match rule by flags" do
    create_flag_annotation_type
    t = create_team
    p0 = create_project team: t
    p1 = create_project team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "flagged_as",
          "rule_value": { flag: 'spam', threshold: 3 }.to_json
        }
      ],
      "actions": [
        {
          "action_definition": "copy_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    assert_equal 0, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    pm = create_project_media project: p0
    data = valid_flags_data
    data[:flags]['spam'] = 2
    create_flag set_fields: data.to_json, annotated: pm
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 0, Project.find(p1.id).project_media_projects.count
    data[:flags]['spam'] = 3
    create_flag set_fields: data.to_json, annotated: pm
    assert_equal 1, Project.find(p0.id).project_media_projects.count
    assert_equal 1, Project.find(p1.id).project_media_projects.count
  end

  test "should get team URL" do
    t = create_team slug: 'test'
    assert_match /^http.*test/, t.reload.url
    t.contact = { web: 'http://meedan.com' }.to_json
    t.save!
    assert_equal 'http://meedan.com', t.reload.url
  end

  test "should define report settings" do
    t = create_team
    t.use_introduction = true
    t.use_disclaimer = true
    t.introduction = random_string
    t.disclaimer = random_string
    t.save!
    t = Team.find(t.id)
    assert t.get_use_introduction
    assert t.get_use_disclaimer
    assert_not_nil t.get_introduction
    assert_not_nil t.get_disclaimer
  end

  test "should get dynamic fields schema for items without list" do
    create_flag_annotation_type
    t = create_team
    pm = create_project_media disable_es_callbacks: false, team: t
    create_flag annotated: pm, disable_es_callbacks: false
    schema = t.dynamic_search_fields_json_schema
    assert_not_nil schema[:properties]['flag_name']
    assert_not_nil schema[:properties]['flag_value']
  end

  test "should match rule when report is published" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media team: t 
    pm2 = create_project_media project: p2
    pm3 = create_project_media team: t
    assert_equal 0, p1.reload.project_media_projects.count
    assert_equal 1, p2.reload.project_media_projects.count
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "report_is_published",
          "rule_value": ""
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    publish_report(pm1)
    publish_report(pm2)
    assert_equal 2, p1.reload.project_media_projects.count
    assert_equal 0, p2.reload.project_media_projects.count
    create_report(pm3, { state: 'published' }, 'publish')
    assert_equal 3, p1.reload.project_media_projects.count
    assert_equal 0, p2.reload.project_media_projects.count
  end

  test "should match rule when report is paused" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media team: t 
    pm2 = create_project_media project: p2
    assert_equal 0, p1.reload.project_media_projects.count
    assert_equal 1, p2.reload.project_media_projects.count
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": [
        {
          "rule_definition": "report_is_paused",
          "rule_value": ""
        }
      ],
      "actions": [
        {
          "action_definition": "move_to_project",
          "action_value": p1.id.to_s
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    r1 = create_report(pm1, { state: 'published' }, 'publish')
    r2 = create_report(pm2, { state: 'published' }, 'publish')
    assert_equal 0, p1.reload.project_media_projects.count
    assert_equal 1, p2.reload.project_media_projects.count
    r1.set_fields = { state: 'paused' }.to_json ; r1.action = 'pause' ; r1.save!
    r2.set_fields = { state: 'paused' }.to_json ; r2.action = 'pause' ; r2.save!
    assert_equal 2, p1.reload.project_media_projects.count
    assert_equal 0, p2.reload.project_media_projects.count
  end
end
