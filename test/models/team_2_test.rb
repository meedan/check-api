require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
require 'sidekiq/testing'

class Team2Test < ActiveSupport::TestCase
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
    create_team_user team: pt, user: pu, role: 'admin'
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
    t = create_team name: 'meedan'
    create_team_user team: t, user: u, role: 'admin'
    # update team as owner
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    with_current_user_and_team(u, t) { t.name = 'meedan_mod'; t.save! }
    assert_equal t.reload.name, 'meedan_mod'
    with_current_user_and_team(u2, t) { t.name = 'meedan_mod2'; t.save! }
    assert_equal t.reload.name, 'meedan_mod2'
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) { t.destroy }
    end
    assert_nothing_raised do
      with_current_user_and_team(u, t) { t.destroy }
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

  test "should not upload a logo that is not an image" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'not-an-image.csv'
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

  test "should validate Slack channel" do
    t = create_team
    slack_notifications = []
    slack_notifications << {
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "@#{random_string}"
    }
    assert_nothing_raised do
      t.slack_notifications = slack_notifications.to_json
      t.save!
    end
    slack_notifications << {
      "label": random_string,
      "event_type": "status_changed",
      "values": ["in_progress"],
      "slack_channel": "#{random_string}"
    }
    assert_raises ActiveRecord::RecordInvalid do
      t.slack_notifications = slack_notifications.to_json
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
    create_team_user team: t, user: u, role: 'admin'
    team = create_team
    perm_keys = [
      "bulk_create Tag", "bulk_update ProjectMedia", "create TagText", "read Team", "update Team",
      "destroy Team", "empty Trash", "create ProjectMedia", "create Account", "create TeamUser",
      "create User", "invite Members", "not_spam ProjectMedia", "restore ProjectMedia", "confirm ProjectMedia", "update ProjectMedia",
      "duplicate Team", "manage TagText", "manage TeamTask", "update Relationship",
      "destroy Relationship", "create TiplineNewsletter", "create Feed", "create FeedTeam", "create FeedInvitation",
      "destroy FeedInvitation", "destroy FeedTeam", "create SavedSearch"
    ].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(team.permissions).keys.sort }

    # load as collaborator
    tu = u.team_users.last; tu.role = 'collaborator'; tu.save!
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
    value = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
      ]
    }
    assert_nothing_raised do
      t.set_media_verification_statuses(value)
      t.save!
    end
    pm = create_project_media team: t
    s = pm.last_verification_status_obj.get_field_value('verification_status_status')
    assert_equal '1', s
    assert_equal 2, t.get_media_verification_statuses[:statuses].size
    # Set verification status via media_verification_statuses
    assert_nothing_raised do
      t.media_verification_statuses = value
      t.save!
    end
    assert_equal 2, Team.find(t.id).media_verification_statuses[:statuses].size
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

  test "should not save custom verification status if it is not a hash" do
    t = create_team
    value = 'invalid_status'
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

  test "should not set statuses without statuses" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      active: '1'
    }
    t.media_verification_statuses = value
    assert_raises ActiveRecord::RecordInvalid do
      t.save!
    end
  end

  test "should set verification statuses to settings" do
    t = create_team
    input = { label: 'Test', active: 'first', default: 'first', statuses: [{ id: 'first', locales: { en: { label: 'Analyzing', description: 'Testing' } }, style: { color: 'bar' } }]}.with_indifferent_access
    output = { label: 'Test', active: 'first', default: 'first', statuses: [{ id: 'first', label: 'Analyzing', locales: { en: { label: 'Analyzing', description: 'Testing' } }, style: { color: 'bar' } }]}.with_indifferent_access
    t.media_verification_statuses = input
    t.source_verification_statuses = input
    t.save!
    assert_equal output, t.get_media_verification_statuses
    assert_equal input, t.get_source_verification_statuses
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
    pm = create_project_media team: t
    a = create_account team: t
    RequestStore.store[:disable_es_callbacks] = true
    t.destroy
    assert_equal 0, TeamUser.where(team_id: id).count
    assert_equal 0, Account.where(team_id: id).count
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should have search id" do
    t = create_team
    assert_not_nil t.search_id
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
      s1 = create_source
      s2 = create_source team: t
      pm1 = create_project_media
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      t.archived = 1
      t.save!
      assert_equal 0, pm1.reload.archived
      assert_equal 1, pm2.reload.archived
      assert_equal 1, pm3.reload.archived
      assert_equal 0, s1.reload.archived
      assert_equal 1, s2.reload.archived
    end
  end

  test "should archive sources, project and project medias in background when team is archived" do
    Sidekiq::Testing.fake! do
      t = create_team
      pm = create_project_media team: t
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      t.archived = true
      t.save!
      assert_equal n + 2, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should not archive project medias in background if team is updated but archived flag does not change" do
    Sidekiq::Testing.fake! do
      t = create_team
      pm = create_project_media team: t
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      t.name = random_string
      t.save!
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should restore sourcesand project medias when team is restored" do
    Sidekiq::Testing.inline! do
      t = create_team
      s1 = create_source team: t
      s2 = create_source
      pm1 = create_project_media
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      t.archived = 1
      t.save!
      assert_equal 0, pm1.reload.archived
      assert_equal 1, pm2.reload.archived
      assert_equal 1, pm3.reload.archived
      t = Team.find(t.id)
      t.archived = 0
      t.save!
      assert_equal 0, pm1.reload.archived
      assert_equal 0, pm2.reload.archived
      assert_equal 0, pm3.reload.archived
      assert_equal 0, s1.reload.archived
      assert_equal 0, s2.reload.archived
    end
  end

  test "should delete sources and project medias in background when team is deleted" do
    Sidekiq::Testing.fake! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      pm = create_project_media team: t
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      with_current_user_and_team(u, t) do
       t.destroy_later
      end
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should anonymize sources and project medias when team is deleted" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      s1 = create_source
      s2 = create_source team: t
      pm1 = create_project_media
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      tg = create_tag annotated: pm2
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        t.destroy_later
      end
      RequestStore.store[:disable_es_callbacks] = false
      assert_not_nil ProjectMedia.where(id: pm1.id).last
      assert_nil ProjectMedia.where(id: pm2.id).last
      assert_nil ProjectMedia.where(id: pm3.id).last
      assert_not_nil Source.where(id: s1.id).last
      assert_nil Source.where(id: s2.id).last.team_id
      assert_nil Tag.where(id: tg.id).last
    end
  end

  test "should not delete team later if doesn't have permission" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'collaborator'
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        t.destroy_later
      end
    end
  end

  test "should empty trash in background" do
    Sidekiq::Testing.fake! do
      t = create_team
      3.times { create_project_media(team: t, archived: true) }
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      t = Team.find(t.id)
      with_current_user_and_team(u, t) do
       t.empty_trash = 1
      end
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should empty trash if has permissions" do
    RequestStore.store[:skip_delete_for_ever] = true
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      3.times { pm = create_project_media(team: t); pm.archived = true; pm.save! }
      2.times { create_project_media(team: t) }
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        assert_difference 'ProjectMedia.count', -3 do
          assert_nothing_raised do
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
      create_team_user user: u, team: t, role: 'collaborator'
      3.times { pm = create_project_media(team: t); pm.archived = true; pm.save! }
      2.times { create_project_media(team: t) }
      with_current_user_and_team(u, t) do
        assert_no_difference 'ProjectMedia.count' do
          assert_raises RuntimeError do
            t.empty_trash = 1
          end
        end
      end
    end
  end

  test "should get trash size" do
    RequestStore.store[:skip_delete_for_ever] = true
    Sidekiq::Testing.inline!
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
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

  test "should have public team id" do
    t = create_team
    assert_kind_of String, t.public_team_id
  end

  test "should have public team alias" do
    t = create_team
    assert_equal t, t.public_team
  end

  test "should return correct public team avatar" do
    t = create_team name: 'Team A', logo: 'rails.png'
    pt = PublicTeam.find t.id
    assert_equal t.avatar, pt.avatar
  end

  test "should duplicate a team and copy team users" do
    team = create_team name: 'Team A', logo: 'rails.png'

    u1 = create_user
    u2 = create_user
    create_team_user team: team, user: u1, role: 'admin', status: 'member'
    create_team_user team: team, user: u2, role: 'editor', status: 'invited'

    RequestStore.store[:disable_es_callbacks] = true
    team.set_languages = ["en", "pt", "es"]
    team.save!
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 0, TeamUser.where(team_id: copy.id).count
    assert_equal team.get_languages, copy.get_languages
    # team attributes
    assert_equal "#{team.slug}-copy-1", copy.slug

    %w(archived private description).each do |att|
      assert_equal team.send(att), copy.send(att)
    end

    assert_difference 'Team.count', -1 do
      copy.destroy
    end
    assert_equal 2, TeamUser.where(team_id: team.id).count
  end

  test "should generate slug for copy based on original" do
    team1 = create_team slug: 'team-a'
    team2 = create_team slug: 'team-a-copy-1'
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team1)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 'team-a-copy-2', copy.slug
  end

  test "should generate slug with 63 maximum chars" do
    team = create_team slug: 'lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-morbi-at'
    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert_equal 'lorem-ipsumsit-amet-consectetur-adipiscing-elit-morbi-at-copy-1', copy.slug
  end

  test "should not notify slack if is being copied" do
    create_slack_bot
    team = create_team
    user = create_user
    create_team_user team: team, user: user, role: 'admin'
    pm = create_project_media team: team
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

  test "should skip validation on team with big image" do
    team = create_team
    user = create_user
    pm = create_project_media team: team, team: team
    tg = create_tag annotated: pm
    File.open(File.join(Rails.root, 'test', 'data', 'rails-photo.jpg')) do |f|
      tg.file = f
    end
    tg.save(validate: false)

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false
    assert copy.valid?
  end

  test "should duplicate a team with saved searches" do
    team = create_team name: 'Team A'
    ss_1 = create_saved_search team: team, filters: {"show"=>["images"]}.to_json
    ss_3 = create_saved_search team: team, filters: nil

    RequestStore.store[:disable_es_callbacks] = true
    copy = Team.duplicate(team)
    RequestStore.store[:disable_es_callbacks] = false

    # Saved searches are copied
    copy_ss_1 = copy.saved_searches.find_by_title(ss_1.title)
    assert_equal ['images'], copy_ss_1.filters['show']

    # Saved searches without filters are copied
    copy_ss_3 = copy.saved_searches.find_by_title(ss_3.title)
    assert_nil copy_ss_3.filters
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

  test "should not save custom statuses if active and default values are not set" do
    t = create_team
    value = {
      label: 'Field label',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
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
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
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
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
      ]
    }
    assert_nothing_raised do
      t = Team.find(t.id)
      t.set_media_verification_statuses(value)
      t.save!
    end
  end

  test "should get owners based on user role" do
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2, role: 'editor'
    assert_equal [u.id], t.owners('admin').map(&:id)
    assert_equal [u2.id], t.owners('editor').map(&:id)
    assert_equal [u.id, u2.id].sort, t.owners(['admin', 'editor']).map(&:id).sort
  end

  test "should get uniq owners by team_users relation" do
    t = create_team
    other_t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: other_t, user: u, role: 'admin'
    assert_equal [u.id], t.owners('admin').map(&:id)
  end

  test "should be related to bots" do
    t = create_team
    tb1 = create_team_bot set_approved: true
    tb2 = create_team_bot team_author_id: t.id
    tbi = create_team_bot_installation team_id: t.id, user_id: tb1.id
    assert_equal 2, t.reload.team_bot_installations.count
    assert_equal [tb1, tb2].sort, t.reload.team_bots.sort
    assert_equal [tb2], t.team_bots_created
    t.destroy!
    assert_nil TeamBotInstallation.where(id: tbi.id).last
    assert_nil BotUser.where(id: tb2.id).last
    assert_not_nil BotUser.where(id: tb1.id).last
  end

  test "should return team tasks" do
    t = create_team
    t2 = create_team
    create_team_task team_id: t2.id
    assert t.auto_tasks().empty?
    tt = create_team_task team_id: t.id
    assert_equal [tt], t.auto_tasks()
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

  test "should get dynamic fields schema" do
    create_flag_annotation_type
    t = create_team slug: 'team'
    t.set_languages []
    t.save!
    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language
    pm1 = create_project_media disable_es_callbacks: false, team: t
    create_dynamic_annotation annotation_type: att, annotated: pm1, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
    pm2 = create_project_media disable_es_callbacks: false, team: t
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

  test "should not crash when emptying trash that has task tags" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      pm = create_project_media team: t
      tk = create_task annotated: pm
      create_tag annotated: tk
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
    assert_match /#{Regexp.escape(CheckConfig.get('storage_asset_host'))}/, t.avatar
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
    t = create_team
    t.set_languages ['en', 'es', 'pt']
    t.save!
    create_flag_annotation_type
    create_tag_text team: t
    2.times { create_team_user team: t }
    create_team_task team_id: t.id, task_type: 'single_choice', options: [{ label: 'Foo' }, { 'label' => 'Bar' }], label: 'Team Task 1'
    create_team_task team_id: t.id, task_type: 'multiple_choice', options: [{ label: 'Test' }], label: 'Team Task 2'
    create_team_task team_id: t.id, task_type: 'free_text', options: [{ label: 'Test' }], label: 'Team Task 3'
    create_team_task
    assert_not_nil t.rules_json_schema
  end

  test "should match rule based on status" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    setup_elasticsearch
    t = create_team
    create_tag_text text: 'test', team_id: t.id
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "status_is",
                "rule_value": "in_progress"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media team: t, disable_es_callbacks: false
    s = pm1.last_status_obj
    s.status = 'in_progress'
    s.save!
    assert_equal ['test'], pm1.get_annotations('tag').map(&:load).map(&:tag_text)
  end

  test "should match rule based on tag" do
    t = create_team
    create_tag_text text: 'tag_foo', team_id: t.id
    create_tag_text text: 'tag_bar', team_id: t.id
    rules = []
    rules << {
      "name": random_string,
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "tagged_as",
                "rule_value": "foo"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "tag_foo"
        }
      ]
    }
    rules << {
      "name": random_string,
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "tagged_as",
                "rule_value": "bar"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "tag_bar"
        }
        
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm1 = create_project_media team: t
    create_tag tag: 'foo', annotated: pm1
    pm2 = create_project_media team: t
    create_tag tag: 'bar', annotated: pm2
    pm3 = create_project_media team: t
    create_tag tag: 'test', annotated: pm3
    assert_includes pm1.get_annotations('tag').map(&:load).map(&:tag_text), 'tag_foo'
    assert_includes pm2.get_annotations('tag').map(&:load).map(&:tag_text), 'tag_bar'
    assert_equal ['test'], pm3.get_annotations('tag').map(&:load).map(&:tag_text)
  end

  test "should match rule based on item type" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'collaborator'
    create_tag_text text: 'test', team_id: t.id
    rules = []
    ['claim', 'uploadedvideo', 'uploadedimage', 'link'].each do |type|
      rules << {
        "name": random_string,
        "project_ids": "",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "type_is",
                  "rule_value": type
                }
              ]
            }
          ]
        },
        "actions": [
          {
          "action_definition": "add_tag",
          "action_value": "test"
          }
        ]
      }
    end
    t.rules = rules.to_json
    t.save!
    assert_equal 4, t.rules_search_fields_json_schema[:properties][:rules][:properties].keys.size
    s = create_source
    c = create_claim_media account: create_valid_account({team: t})
    c.account.sources << s
    pm1 = pm2 = pm3 = pm4 = nil
    CheckSentry.stubs(:notify).raises(StandardError)
    with_current_user_and_team(u, t) do
      pm1 = create_project_media media: c, team: t
      pm2 = create_project_media media: create_uploaded_video, team: t
      pm3 = create_project_media media: create_uploaded_image, team: t
      pm4 = create_project_media media: create_link({team: t}), team: t
    end
    assert_equal ['test'], pm1.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['test'], pm2.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['test'], pm3.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['test'], pm4.get_annotations('tag').map(&:load).map(&:tag_text)
  end

  test "should return number of items in trash, unconfirmed, spam and outside trash" do
    t = create_team
    create_project_media team: t
    create_project_media team: t
    create_project_media team: t
    create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED
    create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED
    create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED
    create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::SPAM
    create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::SPAM
    create_project_media
    t = t.reload
    assert_equal 4, t.medias_count
    assert_equal 2, t.spam_count
    assert_equal 2, t.trash_count
    assert_equal 1, t.unconfirmed_count
  end

  test "should match rule by title" do
    t = create_team
    create_tag_text text: 'test', team_id: t.id
    rules = []
    rules << {
      "name": random_string,
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "title_contains_keyword",
                "rule_value": "test"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","title":"this is a test","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm = create_project_media team: t, media: nil, url: url
    assert_equal ['test'], pm.get_annotations('tag').map(&:load).map(&:tag_text)
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

  test "should not crash if rules throw exception" do
    Team.any_instance.stubs(:apply_rules).raises(RuntimeError)
    t = create_team
    CheckSentry.expects(:notify).once
    create_project_media team: t
    Team.any_instance.unstub(:apply_rules)
  end

  test "should get languages" do
    t = create_team
    assert_equal ['en'], t.get_languages
    t.settings = { languages: ['ar', 'en'], fieldsets: [{ identifier: 'foo', singular: 'foo', plural: 'foos' }] }
    t.save!
    assert_equal ['ar', 'en'], t.get_languages
  end

  test "should not crash if text for keyword rule is nil" do
    t = create_team
    assert_nothing_raised do
      assert !t.text_contains_keyword(nil, 'foo,bar')
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

  test "should match rule by flags" do
    create_flag_annotation_type
    t = create_team
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "flagged_as",
                "rule_value": { flag: 'spam', threshold: 3 }
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_warning_cover",
          "action_value": ""
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm = create_project_media team: t
    assert !pm.show_warning_cover
    data = valid_flags_data
    data[:flags]['spam'] = 1
    d = create_flag set_fields: data.to_json, annotated: pm
    assert !pm.reload.show_warning_cover
    data[:flags]['spam'] = 3
    d.set_fields = data.to_json
    d.save!
    data = d.reload.data.with_indifferent_access
    assert data['show_cover']
    pm = create_project_media team: t
    assert !pm.show_warning_cover
    data[:flags]['spam'] = 3
    d = create_flag set_fields: data.to_json, annotated: pm
    data = d.reload.data.with_indifferent_access
    assert data['show_cover']
  end

  test "should get team URL" do
    t = create_team slug: 'test'
    assert_match /^http.*test/, t.reload.url
    t.save!
    assert_equal "#{CheckConfig.get('checkdesk_client')}/#{t.slug}", t.reload.url
  end

  test "should define report settings" do
    t = create_team
    t.report = {
      en: {
        use_introduction: true,
        use_disclaimer: true,
        introduction: random_string,
        disclaimer: random_string
      }
    }
    t.save!
    t = Team.find(t.id)
    r = t.get_report[:en]
    assert r[:use_introduction]
    assert r[:use_disclaimer]
    assert_not_nil r[:introduction]
    assert_not_nil r[:disclaimer]
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
    create_tag_text text: 'test', team_id: t.id
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "report_is_published",
                "rule_value": ""
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    publish_report(pm1)
    publish_report(pm2)
    create_report(pm3, { state: 'published' }, 'publish')
    assert_equal ['test'], pm1.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['test'], pm2.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['test'], pm3.get_annotations('tag').map(&:load).map(&:tag_text)
  end

  test 'should have a header type available only if there are templates for it' do
    t = create_team
    bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: {}, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    bot.install_to!(t)
    tbi = TeamBotInstallation.where(team: t, user: bot).last
    assert_equal [], t.available_newsletter_header_types
    tbi.set_smooch_template_name_for_newsletter_none_no_articles = 'template_1'
    tbi.set_smooch_template_name_for_newsletter_none_one_articles = 'template_2'
    tbi.set_smooch_template_name_for_newsletter_none_two_articles = 'template_3'
    tbi.set_smooch_template_name_for_newsletter_none_three_articles = 'template_4'
    tbi.save!
    assert_equal ['none', 'link_preview'], t.available_newsletter_header_types
  end

  test "should search for fact-checks and explainers by keywords" do
    Sidekiq::Testing.fake!
    t = create_team
    # Fact-checks
    create_fact_check title: 'Some Other Test', claim_description: create_claim_description(description: 'Claim', project_media: create_project_media(team: t))
    create_fact_check title: 'Bar Bravo Foo Test', claim_description: create_claim_description(context: 'Claim', project_media: create_project_media(team: t))
    create_fact_check title: 'Foo Alpha Bar Test', claim_description: create_claim_description(project_media: create_project_media(team: t))
    assert_equal 3, t.filtered_fact_checks.count
    assert_equal 3, t.filtered_fact_checks(text: 'Test').count
    assert_equal 2, t.filtered_fact_checks(text: 'Foo Bar').count
    assert_equal 2, t.filtered_fact_checks(text: 'Claim').count
    assert_equal 1, t.filtered_fact_checks(text: 'Foo Bar Bravo').count
    assert_equal 1, t.filtered_fact_checks(text: 'Foo Bar Alpha').count
    assert_equal 0, t.filtered_fact_checks(text: 'Foo Bar Delta').count
    # Explainer
    create_explainer title: 'Some Other Test', team: t
    create_explainer title: 'Bar Bravo Foo Test', team: t
    create_explainer title: 'Foo Alpha Bar Test', team: t
    assert_equal 3, t.filtered_explainers.count
    assert_equal 3, t.filtered_explainers(text: 'Test').count
    assert_equal 2, t.filtered_explainers(text: 'Foo Bar').count
    assert_equal 1, t.filtered_explainers(text: 'Foo Bar Bravo').count
    assert_equal 1, t.filtered_explainers(text: 'Foo Bar Alpha').count
    assert_equal 0, t.filtered_fact_checks(text: 'Foo Bar Delta').count
  end

  test "should search for similar articles" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch
    t = create_team
    pm1 = create_project_media quote: 'Foo Bar', team: t
    pm2 = create_project_media quote: 'Foo Bar Test', team: t
    pm3 = create_project_media quote: 'Foo Bar Test Testing', team: t
    ex1 = create_explainer language: 'en', team: t, title: 'Foo Bar'
    ex2 = create_explainer language: 'en', team: t, title: 'Foo Bar Test'
    ex3 = create_explainer language: 'en', team: t, title: 'Foo Bar Test Testing'
    pm1.explainers << ex1
    pm2.explainers << ex2
    pm3.explainers << ex3
    ex_ids = [ex1.id, ex2.id, ex3.id]
    Bot::Smooch.stubs(:search_for_explainers).returns(Explainer.where(id: ex_ids))
    # Return Explainer if no FactCheck exists
    assert_equal ex_ids, t.search_for_similar_articles('Foo Bar').map(&:id).sort
    fact_checks = []
    [pm1, pm2, pm3].each do |pm|
      cd = create_claim_description description: pm.title, project_media: pm
      fc = create_fact_check claim_description: cd, title: pm.title
      fact_checks << fc.id
    end
    [pm1, pm2, pm3].each { |pm| publish_report(pm) }
    sleep 2
    # Should return FactCheck even there is an Explainer exists
    assert_equal fact_checks.sort, t.search_for_similar_articles('Foo Bar').map(&:id).sort
    # Verirfy limit option
    stub_configs({ 'most_relevant_team_limit' => 1 }) do
      assert_equal [fact_checks.first], t.search_for_similar_articles('Foo Bar').map(&:id).sort
    end
    Bot::Smooch.unstub(:search_for_explainers)
  end

  test "should notify Sentry if it fails to retrieve relevant articles" do
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks_no_cache).raises(StandardError)
    CheckSentry.expects(:notify).once
    t = create_team
    assert_equal [], t.search_for_similar_articles('Test')
  end

  test "should extract slug from URL using URI.extract" do
    url = "https://example.com/my-team"
    assert_equal "my-team", Team.slug_from_url(url)

    text_with_url = "Some text [http://example.com/team-slug] more text"
    assert_equal "team-slug", Team.slug_from_url(text_with_url)

    complex_url = "https://example.com/team123/extra/info"
    assert_equal "team123", Team.slug_from_url(complex_url)
  end

  test "should return statistics platforms" do
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    create_tipline_request project_media: pm1, platform: 'whatsapp'
    create_tipline_request project_media: pm2, platform: 'telegram'
    assert_equal ['telegram', 'whatsapp'].sort, t.statistics_platforms.sort
  end

  test "should return empty array if no statistics platforms" do
    t = create_team
    assert_equal [], t.statistics_platforms
  end

  test "should get filtered articles by keyword" do
    Sidekiq::Testing.fake!
    t = create_team
    create_fact_check title: 'Test fact-check', claim_description: create_claim_description(description: 'Claim', project_media: create_project_media(team: t))
    create_explainer title: 'Test explainer', team: t
    assert_equal 2, t.filtered_articles(text: 'Test?').count
  end

  test "should install tipline when workspace is created" do
    settings = [{ 'name' => 'smooch_workflows', 'default' => ::Bot::Smooch.default_settings.clone }]
    bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: settings, set_events: [], default: true, set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    assert_difference "TeamBotInstallation.where(user_id: #{bot.id}).count" do
      create_team
    end
  end
end
