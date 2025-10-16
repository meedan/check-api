require_relative '../test_helper'

class AbilityTest < ActiveSupport::TestCase

  def teardown
    super
    puts('If permissions changed, please remember to update config/permissions_info.yml') unless passed?
  end

  # Verify comman permisions for all roles ('collaborator', 'editor', 'admin')
  ['collaborator', 'editor', 'admin'].each do |role|
    test "#{role} permissions for media" do
      u = create_user
      t = create_team
      tu = create_team_user team: t, user: u , role: role
      m = create_valid_media
      m2 = create_valid_media
      pm = create_project_media team: t, media: m
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, Media)
        assert ability.can?(:update, m)
        assert ability.can?(:destroy, m)
        assert ability.cannot?(:update, m2)
        assert ability.cannot?(:destroy, m2)
      end
    end

    test "#{role} permissions for status" do
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user team: t, user: u, role: role
      pm = create_project_media team: t
      pm2 = create_project_media team: t2
      s = create_status status: 'verified', annotated: pm
      s2 = create_status status: 'verified', annotated: pm2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, s)
        assert ability.can?(:update, s)
        assert ability.cannot?(:update, s2)
        assert ability.cannot?(:destroy, s2)
      end
    end

    test "#{role} permissions for task" do
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user team: t, user: u, role: role
      pm = create_project_media team: t
      tk = create_task annotator: u, annotated: pm
      pm2 = create_project_media team: t2
      tk2 = create_task annotator: u, annotated: pm2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, tk)
        assert ability.can?(:update, tk)
        assert ability.can?(:destroy, tk)
        assert ability.cannot?(:update, tk2)
        assert ability.cannot?(:destroy, tk2)
      end
    end

    test "#{role} permissions for dynamic annotation" do
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user team: t, user: u, role: role
      pm = create_project_media team: t
      pm2 = create_project_media team: t2
      da = create_dynamic_annotation annotated: pm
      da2 = create_dynamic_annotation annotated: pm2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, Dynamic)
        assert ability.can?(:update, da)
        assert ability.can?(:destroy, da)
        assert ability.cannot?(:update, da2)
        assert ability.cannot?(:destroy, da2)
      end
    end

    test "#{role} permissions for tipline request" do
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user team: t, user: u, role: role
      pm = create_project_media team: t
      pm2 = create_project_media team: t2
      tr = create_tipline_request team_id: t.id, associated: pm
      tr2 = create_tipline_request team_id: t2.id, associated: pm2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, TiplineRequest)
        assert ability.can?(:update, tr)
        assert ability.can?(:destroy, tr)
        assert ability.cannot?(:update, tr2)
        assert ability.cannot?(:destroy, tr2)
      end
    end

    test "#{role} permissions for tag" do
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user team: t, user: u, role: role
      pm = create_project_media team: t
      pm2 = create_project_media team: t2
      tg = create_tag tag: 'media_tag', annotated: pm
      tg2 = create_tag tag: 'media_tag', annotated: pm2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, tg)
        assert ability.can?(:update, tg)
        assert ability.can?(:destroy, tg)
        assert ability.cannot?(:create, tg2)
        assert ability.cannot?(:update, tg2)
        assert ability.cannot?(:destroy, tg2)
      end
    end

    test "should #{role} destroy annotations related to his team" do
      u = create_user
      t = create_team
      t2 = create_team
      create_team_user user: u, team: t, role: 'admin'
      pm1 = create_project_media team: t
      pm2 = create_project_media team: t2
      a1 = create_annotation annotated: pm1
      a2 = create_annotation annotated: pm2
      with_current_user_and_team(u, t) do
        a = Ability.new
        assert a.can?(:destroy, a1)
        assert a.cannot?(:destroy, a2)
      end
    end
  end

  # Verify comman permisions for  'editor' and 'admin'
  ['editor', 'admin'].each do |role|
    test "#{role} permissions for account source" do
      u = create_user
      t = create_team
      t2 = create_team
      a = create_valid_account team: t
      a2 = create_valid_account team: t2
      s = create_source team: t
      s2 = create_source team: t2
      tu = create_team_user user: u , team: t, role: role
      as = create_account_source source: s, account: a
      as2 = create_account_source source: s2, account: a2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        # account permissions
        assert ability.can?(:create, a)
        assert ability.can?(:update, a)
        assert ability.can?(:destroy, a)
        assert ability.cannot?(:create, a2)
        assert ability.cannot?(:update, a2)
        assert ability.cannot?(:destroy, a2)
        # source permissions
        assert ability.can?(:create, s)
        assert ability.can?(:update, s)
        assert ability.can?(:destroy, s)
        assert ability.cannot?(:create, s2)
        assert ability.cannot?(:update, s2)
        assert ability.cannot?(:destroy, s2)
        # AccountSource permissions
        assert ability.can?(:create, as)
        assert ability.can?(:update, as)
        assert ability.can?(:destroy, as)
        assert ability.cannot?(:update, as2)
        assert ability.cannot?(:destroy, as2)
      end
    end

    test "#{role} permissions for tag text" do
      t1 = create_team
      t2 = create_team
      u = create_user
      create_team_user team: t1, user: u, role: role
      ta1 = create_tag_text team_id: t1.id
      ta2 = create_tag_text team_id: t2.id
      with_current_user_and_team(u, t1) do
        ability = Ability.new
        assert ability.can?(:create, ta1)
        assert ability.can?(:update, ta1)
        assert ability.can?(:destroy, ta1)
      end
      with_current_user_and_team(u, t2) do
        ability = Ability.new
        assert ability.cannot?(:create, ta2)
        assert ability.cannot?(:update, ta2)
        assert ability.cannot?(:destroy, ta2)
      end
    end

    test "#{role} should edit, send to trash and destroy any report" do
      t = create_team
      u = create_user
      tu = create_team_user team: t, user: u, role: role
      pm = create_project_media team: t
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:update, pm)
        assert ability.can?(:destroy, pm)
        pm.update_columns(archived: CheckArchivedFlags::FlagCodes::TRASHED)
        pm = pm.reload
        assert ability.can?(:update, pm)
        assert ability.can?(:destroy, pm)
      end
    end

    test "#{role} can empty trash" do
      u = create_user
      t = create_team
      create_team_user user: u, team: t , role: role
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:destroy, :trash)
      end
    end

    test "#{role} permissions for ProjectMedia" do
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user team: t, user: u , role: role
      pm = create_project_media team: t
      pm2 = create_project_media team: t2
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:create, ProjectMedia)
        assert ability.can?(:update, pm)
        assert ability.can?(:destroy, pm)
        assert ability.can?(:administer_content, pm)
        assert ability.cannot?(:update, pm2)
        assert ability.cannot?(:destroy, pm2)
        assert ability.cannot?(:administer_content, pm2)
      end
    end

    test "should #{role} destroy annotation versions" do
      create_verification_status_stuff
      with_versioning do
        u = create_user
        t = create_team
        tu = create_team_user team: t, user: u, role: role
        pm = create_project_media team: t
        with_current_user_and_team(u, t) do
          s = create_status annotated: pm, status: 'verified'
          tag = create_tag annotated: pm
          s_v = s.versions.last
          tag_v = tag.versions.last
          ability = Ability.new
          # Status versions
          assert ability.can?(:create, s_v)
          assert ability.cannot?(:update, s_v)
          assert ability.can?(:destroy, s_v)
          # Tag versions
          assert ability.can?(:create, tag_v)
          assert ability.cannot?(:update, tag_v)
          assert ability.can?(:destroy, tag_v)
        end
      end
    end

    test "#{role} should edit own annotation and destroy any annotation from trash and should destroy respective log entry" do
      with_versioning do
        t = create_team
        u = create_user
        tu = create_team_user team: t, user: u, role: role
        pm = create_project_media team: t
        tag = create_tag annotated: pm, annotator: u
        tag2 = create_tag annotated: pm
        with_current_user_and_team(u, t) do
          ability = Ability.new
          assert ability.can?(:update, tag)
          assert ability.can?(:destroy, tag)
          assert ability.can?(:update, tag2)
          assert ability.can?(:destroy, tag2)
          tag.destroy!
          v = Version.last
          assert ability.can?(:destroy, v)
          tag2.destroy!
          v = Version.last
          assert ability.can?(:destroy, v)
        end
      end
    end
  end

  test "authenticated permissions for team" do
    u = create_user
    t = create_team
    with_current_user_and_team(u, nil) do
      ability = Ability.new
      assert ability.cannot?(:create, Team)
      assert ability.cannot?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "collaborator permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'collaborator'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, Team)
      assert ability.cannot?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "editor permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'editor'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, Team)
      assert ability.can?(:update, t)
      assert ability.cannot?(:destroy, t)
      assert ability.cannot?(:update, t2)
      assert ability.cannot?(:destroy, t2)
    end
  end

  test "admin permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'admin'
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'admin'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, Team)
      assert ability.can?(:update, t)
      assert ability.can?(:destroy, t)
      assert ability.cannot?(:update, t2)
      assert ability.cannot?(:destroy, t2)
    end
  end

  test "authenticated permissions for teamUser" do
    u = create_user
    tu = create_team_user user: u
    User.current = u
    ability = Ability.new
    assert ability.cannot?(:create, TeamUser)
    assert ability.cannot?(:update, tu)
    assert ability.can?(:destroy, tu)
  end

  test "collaborator permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'collaborator'
    tu2 = create_team_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, TeamUser)
      assert ability.cannot?(:update, tu)
      assert ability.can?(:destroy, tu)
      assert ability.cannot?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
    end
  end

  test "editor permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    u2 = create_user
    tu2 = create_team_user team: t, role: 'collaborator'
    tu_other = create_team_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
      assert ability.can?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
      tu2.update_column(:role, 'admin')
      assert ability.cannot?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
      assert ability.cannot?(:update, tu_other)
      assert ability.cannot?(:destroy, tu_other)
    end
  end

  test "admin permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'admin'
    u2 = create_user
    tu2 = create_team_user team: t, role: 'editor'
    tu_other = create_team_user

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
      assert ability.can?(:update, tu2)
      assert ability.can?(:destroy, tu2)
      assert ability.cannot?(:update, tu_other)
      assert ability.cannot?(:destroy, tu_other)
    end
  end

  test "collaborator permissions for ProjectMedia" do
    u = create_user
    t = create_team
    t2 = create_team
    tu = create_team_user team: t, user: u , role: 'collaborator'
    pm = create_project_media team: t
    pm2 = create_project_media team: t2
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, ProjectMedia)
      assert ability.can?(:update, pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.can?(:administer_content, pm)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:destroy, pm2)
      assert ability.cannot?(:administer_content, pm2)
    end
  end

  test "collaborator permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'collaborator'
    u_test1 = create_user
    tu_test1 = create_team_user user: u_test1, role: 'admin'
    u_test2 = create_user
    tu_test2 = create_team_user team: t, user: u_test2, role: 'editor'
    u_test3 = create_user
    tu_test3 = create_team_user team: t, user: u_test3, role: 'collaborator'

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, u)
      assert ability.can?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)
      assert ability.cannot?(:update, u_test2)
      assert ability.cannot?(:destroy, u_test2)
      assert ability.cannot?(:update, u_test3)
      assert ability.cannot?(:destroy, u_test3)
      assert ability.cannot?(:update, u2_test)
      assert ability.cannot?(:destroy, u2_test)
    end
  end

  test "editor permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'collaborator'
    u_test1 = create_user
    tu_test1 = create_team_user team: t, user: u_test1, role: 'admin'
    u_test2 = create_user
    tu_test2 = create_team_user team: t, user: u_test2, role: 'collaborator'
    u_test3 = create_user
    tu_test3 = create_team_user team: t, user: u_test3, role: 'collaborator'

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, u)
      assert ability.can?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)
      assert ability.cannot?(:update, u_test2)
      assert ability.cannot?(:destroy, u_test2)
      assert ability.cannot?(:update, u_test3)
      assert ability.cannot?(:destroy, u_test3)
      assert ability.cannot?(:update, u2_test)
      assert ability.cannot?(:destroy, u2_test)
    end
  end

  test "admin permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'collaborator'
    u_test1 = create_user
    tu_test1 = create_team_user team: t, user: u_test1, role: 'editor'

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, u)
      assert ability.can?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      tu_test1.update_column(:role, 'editor')

      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      tu_test1.update_column(:role, 'collaborator')

      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      assert ability.cannot?(:update, u2_test)
      assert ability.cannot?(:destroy, u2_test)
    end
  end

  test "check annotation permissions" do
    # test the create/update/destroy operations
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    pm = create_project_media team: t
    task = create_task annotated: pm
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        task.save
      end
    end

    tu.role = 'admin'; tu.save!

    with_current_user_and_team(u, create_team) do
      assert_raise RuntimeError do
        task.save
      end
    end

    Rails.cache.clear
    u = User.find(u.id)
    task.label = 'for testing';task.save!
    assert_equal task.label, 'for testing'

    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        task.destroy
      end
    end
  end

  test "admin permissions for embed" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    em = create_metadata annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, em)
      assert ability.can?(:update, em)
      assert ability.can?(:destroy, em)
    end
  end

  test "read ability for user in public team" do
    u = create_user
    t1 = create_team
    tu = create_team_user user: u , team: t1
    t2 = create_team private: true
    m = create_valid_media
    pma = create_project_media team: t1, media: m
    pmb = create_project_media team: t2, media: m
    with_current_user_and_team(u, t1) do
      ability = Ability.new
      assert ability.can?(:read, t1)
      assert ability.cannot?(:read, t2)
      assert ability.can?(:read, m)
    end
  end

  test "read ability for user in private team with member status" do
    u = create_user
    t1 = create_team
    t2 = create_team private: true
    tu = create_team_user user: u , team: t2
    m = create_valid_media
    pma = create_project_media team: t1, media: m
    pmb = create_project_media team: t2, media: m
    with_current_user_and_team(u, tu) do
      ability = Ability.new
      assert ability.can?(:read, t1)
      assert ability.can?(:read, t2)
      assert ability.can?(:read, m)
    end
  end

  test "read ability for user in private team with non member status" do
    u = create_user
    t1 = create_team
    t2 = create_team private: true
    tu = create_team_user user: u , team: t2, status: 'banned'
    m = create_valid_media
    pma = create_project_media team: t1, media: m
    pmb = create_project_media team: t2, media: m
    with_current_user_and_team(u, t2) do
      ability = Ability.new
      assert ability.can?(:read, t1)
      assert ability.cannot?(:read, t2)
      assert ability.can?(:read, m)
    end
  end

  test "only admin users can manage all" do
    u = create_user
    u.is_admin = true
    u.save
    ability = Ability.new(u)
    assert ability.can?(:manage, :all)
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    a = create_account
    team_perms = [
      "bulk_create Tag", "bulk_update ProjectMedia", "create TagText", "read Team", "update Team", "destroy Team", "empty Trash",
      "create Account", "create TeamUser", "create User", "create ProjectMedia", "invite Members",
      "not_spam ProjectMedia", "restore ProjectMedia", "confirm ProjectMedia", "update ProjectMedia", "duplicate Team", "create Feed",
      "manage TagText", "manage TeamTask", "update Relationship", "destroy Relationship", "create TiplineNewsletter",
      "create FeedInvitation", "create FeedTeam", "destroy FeedInvitation", "destroy FeedTeam", "create SavedSearch"
    ]
    
    with_current_user_and_team(u, t) do
      assert_equal team_perms.sort, JSON.parse(t.permissions).keys.sort
      assert_equal ["read Account", "update Account", "destroy Account", "create Media", "create Link", "create Claim"].sort, JSON.parse(a.permissions).keys.sort
    end
  end

  test "should read source without user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    s = create_source user: nil
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, s)
    end
  end

  test "should read own source" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    s = create_source user: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, s)
    end
  end

  test "should not read source from other user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    s = create_source user: create_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:read, s)
    end
  end

  test "authenticated permissions for source" do
    u = create_user
    s = u.source
    s2 = create_source team: create_team, user: u
    User.current = u
    ability = Ability.new
    # auth users can only update own source with team nil [profile]
    assert ability.can?(:update, s)
    assert ability.cannot?(:update, s2)
  end

  test "collaborator permissions for source" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user team: t, user: u, role: 'collaborator'
    s = create_source team: t
    s2 = create_source team: t2
    s2 = create_source team: create_team, user: u
    with_current_user_and_team(u, t) do
    ability = Ability.new
      assert ability.can?(:create, s)
      assert ability.cannot?(:update, s)
      assert ability.cannot?(:destroy, s)
      assert ability.cannot?(:create, s2)
      assert ability.cannot?(:update, s2)
      assert ability.cannot?(:destroy, s2)
    end
  end

  test "should user destroy own request to join a team" do
    u = create_user
    t = create_team
    tu1 = create_team_user user: u, team: t
    tu2 = create_team_user user: create_user, team: t
    with_current_user_and_team(u, t) do
      a = Ability.new
      assert a.can?(:destroy, tu1)
      assert a.cannot?(:destroy, tu2)
    end
  end

  test "collaborator can manage own dynamic fields" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    pm = create_project_media team: t
    tk = create_task annotated: pm
    create_annotation_type annotation_type: 'response'
    a1 = create_dynamic_annotation annotation_type: 'response', annotator: u, annotated: tk
    f1 = create_field annotation_type: nil, annotation_id: a1.id
    a2 = create_dynamic_annotation annotation_type: 'response'
    f2 = create_field annotation_type: nil, annotation_id: a2.id

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, f1)
      assert ability.can?(:update, f1)
      assert ability.can?(:destroy, f1)
      assert ability.cannot?(:create, f2)
      assert ability.cannot?(:update, f2)
      assert ability.cannot?(:destroy, f2)
    end
  end

  test "api key read permissions for everything" do
    t = create_team private: true
    pm = create_project_media team: t
    a = create_api_key
    ApiKey.current = a
    ability = Ability.new
    assert ability.can?(:read, pm)
    assert ability.cannot?(:update, pm)
    assert ability.cannot?(:destroy, pm)
    ApiKey.current = nil
  end

  test "api key cud permissions" do
    a = create_api_key
    t = create_team private: true
    t2 = create_team
    u = create_bot_user api_key_id: a.id
    tu = create_team_user team: t, user: u, role: 'admin'
    u = User.find(u.id)
    ApiKey.current = a
    User.current = u
    ability = Ability.new
    assert ability.cannot?(:create, Team)
    assert ability.can?(:update, t)
    assert ability.cannot?(:update, t2)
    assert ability.cannot?(:destroy, t)
    assert ability.cannot?(:create, User)
    assert ability.cannot?(:destroy, u)
    assert ability.cannot?(:create, TeamUser)
    assert ability.cannot?(:update, tu)
    assert ability.cannot?(:destroy, tu)
    ApiKey.current = nil
    User.current = nil
  end

  test "bot user permissions" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    b = create_bot_user team_author_id: create_team.id
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, BotUser)
      assert ability.cannot?(:update, b)
      assert ability.cannot?(:destroy, b)
    end
    u2 = create_user is_admin: true
    with_current_user_and_team(u2, t) do
      ability = Ability.new
      assert ability.can?(:create, BotUser)
      assert ability.can?(:update, b)
      assert ability.can?(:destroy, b)
    end
  end

  test "annotation permissions" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    task1 = create_task annotated: pm

    u2 = create_user
    t2 = create_team
    tu2 = create_team_user team: t2, user: u2, role: 'admin'
    pm2 = create_project_media team: t2
    task2 = create_task annotated: pm2

    with_current_user_and_team(u2, t2) do
      ability = Ability.new
      assert ability.cannot?(:create, task1)
      assert ability.can?(:create, task2)
    end

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, task2)
      assert ability.can?(:create, task1)
    end
  end

  test "collaborator should edit, send to trash but not to destroy report" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'collaborator'
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, pm)
      assert ability.cannot?(:destroy, pm)
      pm.update_columns(archived: CheckArchivedFlags::FlagCodes::TRASHED)
      pm = pm.reload
      assert ability.can?(:update, pm)
      assert ability.cannot?(:destroy, pm)
    end
  end

  test "collaborator should edit and destroy own annotation from trash but should not destroy respective log entry" do
    with_versioning do
      t = create_team
      u = create_user
      tu = create_team_user team: t, user: u, role: 'collaborator'
      pm = create_project_media team: t
      task1 = create_task annotated: pm, annotator: u
      task2 = create_task annotated: pm
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:update, task1)
        assert ability.can?(:destroy, task1)
        assert ability.can?(:update, task2)
        assert ability.can?(:destroy, task2)
        task1.destroy!
        v = PaperTrail::Version.last
        assert ability.cannot?(:destroy, v)
      end
    end
  end

  test "collaborator should destroy project media version" do
    with_versioning do
      t = create_team
      u = create_user
      tu = create_team_user team: t, user: u, role: 'collaborator'
      with_current_user_and_team(u, t) do
        ability = Ability.new
        pm = create_project_media team: t
        v = pm.versions.last
        assert ability.can?(:destroy, v)
      end
    end
  end

  test "collaborator should not send to trash, edit or destroy team" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'collaborator'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "editor should not send to trash or destroy team" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'editor'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "admin should send to trash, edit or destroy own team" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'admin'
    t2 = create_team
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, t)
      assert ability.can?(:destroy, t)
    end
    with_current_user_and_team(u, t2) do
      ability = Ability.new
      assert ability.cannot?(:update, t2)
      assert ability.cannot?(:destroy, t2)
    end
  end

  test "editor should not downgrade admin role" do
    t = create_team
    u = create_user
    u2 = create_user
    u3 = create_user
    tu1 = create_team_user team: t, user: u, role: 'editor'
    tu2 = create_team_user team: t, user: u2, role: 'admin'
    tu2 = TeamUser.find(tu2.id)
    tu3 = create_team_user team: t, user: u3, role: 'collaborator'
    tu3 = TeamUser.find(tu3.id)
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        tu3.role = 'editor'
        tu3.save!
      end

      assert_raises RuntimeError do
        tu2.role = 'editor'
        tu2.save!
      end
    end
  end

  test "permissions for team bot" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u, role: 'admin'
    tb1 = create_team_bot team_author_id: t1.id
    tb2 = create_team_bot team_author_id: t2.id
    with_current_user_and_team(u, t1) do
      ability = Ability.new
      assert ability.can?(:create, tb1)
      assert ability.can?(:update, tb1)
      assert ability.can?(:destroy, tb1)
    end
    with_current_user_and_team(u, t2) do
      ability = Ability.new
      assert ability.cannot?(:create, tb2)
      assert ability.cannot?(:update, tb2)
      assert ability.cannot?(:destroy, tb2)
    end
  end

  test "permissions for team bot installation" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u, role: 'admin'
    tbi1 = create_team_bot_installation team_id: t1.id
    tbi2 = create_team_bot_installation team_id: t2.id
    with_current_user_and_team(u, t1) do
      ability = Ability.new
      assert ability.can?(:create, tbi1)
      assert ability.can?(:update, tbi1)
      assert ability.can?(:destroy, tbi1)
    end
    with_current_user_and_team(u, t2) do
      ability = Ability.new
      assert ability.cannot?(:create, tbi2)
      assert ability.cannot?(:update, tbi2)
      assert ability.cannot?(:destroy, tbi2)
    end
  end

  test "read ability for bot user" do
    t1 = create_team private: false
    tu1 = create_team_bot team_author_id: t1.id
    bu1 = tu1

    t2 = create_team private: true
    tu2 = create_team_bot team_author_id: t2.id
    bu2 = tu2

    t3 = create_team private: true
    tu3 = create_team_bot team_author_id: t3.id
    bu3 = tu3

    u = create_user
    create_team_user user: u, team: t2

    with_current_user_and_team(u, t1) do
      ability = Ability.new
      assert ability.can?(:read, bu1)
    end
    with_current_user_and_team(u, t2) do
      ability = Ability.new
      assert ability.can?(:read, bu2)
    end
    with_current_user_and_team(u, t3) do
      ability = Ability.new
      assert ability.cannot?(:read, bu3)
    end
  end

  test "read ability for team bot" do
    t = create_team
    u = create_user
    create_team_user team_id: t.id, user_id: u.id
    tb1 = create_team_bot set_approved: false
    tb2 = create_team_bot set_approved: true
    tb3 = create_team_bot set_approved: false, team_author_id: t.id

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, tb1)
      assert ability.can?(:read, tb2)
      assert ability.can?(:read, tb3)
    end
  end

  test "collaborator permissions for tag text" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'collaborator'
    ta1 = create_tag_text team_id: t.id
    ta2 = create_tag_text
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, ta1)
      assert ability.cannot?(:update, ta1)
      assert ability.cannot?(:destroy, ta1)
      assert ability.cannot?(:create, ta2)
      assert ability.cannot?(:update, ta2)
      assert ability.cannot?(:destroy, ta2)
    end
  end

  test "permissions for assignment" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    task1 = create_task annotated: pm
    task1.assign_user(u.id)
    a = task1.assignments.last

    t2 = create_team
    u2 = create_user
    create_team_user team: t2, user: u2
    pm2 = create_project_media team: t2
    task2 = create_task annotated: pm2
    task2.assign_user(u2.id)
    a2 = task2.assignments.last

    # admin, editor and collaborator can assign/unassign annotations of same team
    ['admin', 'editor', 'collaborator'].each do |role|
      u = create_user
      create_team_user team_id: t.id, user_id: u.id, role: role
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.can?(:destroy, a)
        assert ability.can?(:create, a)
        assert ability.cannot?(:destroy, a2)
        assert ability.cannot?(:create, a2)
      end
    end
  end

  test "super admin permissions for import spreadsheet" do
    t = create_team
    u = create_user

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert !ability.can?(:import, t)
    end
    u.is_admin = true
    u.save
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:import, t)
    end
  end

  test "team collaborator cannot import spreadsheet" do
    t1 = create_team
    t2 = create_team
    u1 = create_user
    create_team_user team: t1, user: u1, role: 'collaborator'
    with_current_user_and_team(u1, t1) do
      ability = Ability.new
      assert ability.cannot?(:import_spreadsheet, t1)
      assert ability.cannot?(:import_spreadsheet, t2)
    end
  end

  test "should be able to leave team" do
    TeamUser.role_types.each do |role|
      User.current = Team.current = nil
      u = create_user
      t = create_team
      t2 = create_team
      tu = create_team_user user: u, team: t, status: 'member', role: role
      tu2 = create_team_user user: u, team: t2, status: 'requested', role: role
      with_current_user_and_team(u, t) do
        if role != 'admin' && role != 'editor'
          assert_raises RuntimeError do
            tu = TeamUser.find(tu.id)
            tu.role = 'editor'
            tu.save!
          end
        end
      end
      with_current_user_and_team(u, t2) do
        if role != 'admin' && role != 'editor'
          assert_raises RuntimeError do
            tu2 = TeamUser.find(tu2.id)
            tu2.status = 'member'
            tu2.save!
          end
          assert_raises RuntimeError do
            tu = TeamUser.find(tu.id)
            tu.user_id = create_user.id
            tu.save!
          end
        end
      end
    end
  end

  test "restore and update project media permissions at team level" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    with_current_user_and_team(u, t) do
      assert JSON.parse(t.permissions)['restore ProjectMedia']
      assert JSON.parse(t.permissions)['update ProjectMedia']
    end
  end

  test "permissions for project media user" do
    t = create_team
    u1 = create_user
    u2 = create_user
    pm = create_project_media
    pmu1 = ProjectMediaUser.create! project_media: pm, user: u1, read: true
    pmu2 = ProjectMediaUser.create! project_media: pm, user: u2, read: true
    with_current_user_and_team(u1, t) do
      ability = Ability.new
      assert ability.can?(:create, pmu1)
      assert ability.can?(:update, pmu1)
      assert ability.can?(:destroy, pmu1)
      assert ability.can?(:read, pmu1)
      assert ability.cannot?(:create, pmu2)
      assert ability.cannot?(:update, pmu2)
      assert ability.cannot?(:destroy, pmu2)
      assert ability.cannot?(:read, pmu2)
    end
    with_current_user_and_team(u2, t) do
      ability = Ability.new
      assert ability.cannot?(:create, pmu1)
      assert ability.cannot?(:update, pmu1)
      assert ability.cannot?(:destroy, pmu1)
      assert ability.cannot?(:read, pmu1)
      assert ability.can?(:create, pmu2)
      assert ability.can?(:update, pmu2)
      assert ability.can?(:destroy, pmu2)
      assert ability.can?(:read, pmu2)
    end
  end

  test "permissions for tipline newsletter" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    tn1 = create_tipline_newsletter(team: t)
    tn2 = create_tipline_newsletter
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tn1)
      assert ability.can?(:update, tn1)
      assert ability.can?(:destroy, tn1)
      assert ability.cannot?(:create, tn2)
      assert ability.cannot?(:update, tn2)
      assert ability.cannot?(:destroy, tn2)
    end
  end

  test "permissions for feed invitation" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    f = create_feed team: t
    fi1 = create_feed_invitation feed: f
    fi2 = create_feed_invitation
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, fi1)
      assert ability.can?(:update, fi1)
      assert ability.can?(:destroy, fi1)
      assert ability.cannot?(:create, fi2)
      assert ability.cannot?(:update, fi2)
      assert ability.cannot?(:destroy, fi2)
    end
  end

  test "permissions for feed team" do
    t1 = create_team
    t2 = create_team
    t3 = create_team
    u1 = create_user
    u2 = create_user
    u3 = create_user
    create_team_user user: u1, team: t1, role: 'admin'
    create_team_user user: u2, team: t2, role: 'admin'
    create_team_user user: u3, team: t3, role: 'admin'
    f = create_feed team: t1
    ft2 = create_feed_team feed: f, team: t2
    ft3 = create_feed_team feed: f, team: t3
    with_current_user_and_team(u1, t1) do
      ability = Ability.new
      assert ability.can?(:destroy, ft2)
      assert ability.can?(:destroy, ft3)
      assert ability.can?(:destroy, f)
    end
    with_current_user_and_team(u2, t2) do
      ability = Ability.new
      assert ability.can?(:destroy, ft2)
      assert ability.cannot?(:destroy, ft3)
      assert ability.cannot?(:destroy, f)
    end
    with_current_user_and_team(u3, t3) do
      ability = Ability.new
      assert ability.cannot?(:destroy, ft2)
      assert ability.can?(:destroy, ft3)
      assert ability.cannot?(:destroy, f)
    end
  end
end
