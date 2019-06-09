require_relative '../test_helper'

class AbilityTest < ActiveSupport::TestCase

  def teardown
    super
    puts('If permissions changed, please remember to update config/permissions_info.yml') unless passed?
  end

  test "contributor permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'contributor'
    p = create_project
    own_project = create_project(user: u)
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, Project)
      assert ability.cannot?(:update, p)
      assert ability.cannot?(:update, own_project)
      assert ability.cannot?(:destroy, p)
      assert ability.cannot?(:destroy, own_project)
    end
  end

  test "journalist permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'journalist'
    p = create_project team: t
    own_project = create_project team: t, user: u
    p2 = create_project user: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Project)
      assert ability.can?(:update, own_project)
      assert ability.cannot?(:destroy, own_project)
      assert ability.cannot?(:update, p)
      assert ability.cannot?(:destroy, p)
      assert ability.cannot?(:update, p2)
      assert ability.cannot?(:destroy, p2)
    end
  end

  test "editor permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'editor'
    p = create_project team: t
    own_project = create_project team: t, user: u
    p2 = create_project
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Project)
      assert ability.can?(:update, p)
      assert ability.can?(:update, own_project)
      assert ability.cannot?(:destroy, p)
      assert ability.cannot?(:destroy, own_project)
      assert ability.cannot?(:update, p2)
      assert ability.cannot?(:destroy, p2)
    end
  end

  test "owner permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'owner'
    p = create_project team: t
    own_project = create_project team: t, user: u
    p2 = create_project
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Project)
      assert ability.can?(:update, p)
      assert ability.can?(:update, own_project)
      assert ability.can?(:destroy, p)
      assert ability.can?(:destroy, own_project)
      assert ability.cannot?(:update, p2)
      assert ability.cannot?(:destroy, p2)
    end
  end

  test "contributor permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'contributor'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    own_pm = create_project_media project: p, media: own_media, user: u
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    own_media = create_valid_media user_id: u.id
    pm_own = create_project_media media: own_media, user: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Media)
      assert ability.cannot?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m)
      assert ability.cannot?(:destroy, own_media)
      assert ability.cannot?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.cannot?(:administer_content, pm)
      assert ability.cannot?(:administer_content, own_pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.cannot?(:destroy, own_pm)
      assert ability.cannot?(:update, m2)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m2)
      assert ability.cannot?(:destroy, own_media)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:update, pm_own)
      assert ability.cannot?(:destroy, pm2)
      assert ability.cannot?(:destroy, pm_own)
    end
  end

  test "journalist permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'journalist'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    own_pm = create_project_media project: p, media: own_media, user: u
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    pm_own = create_project_media media: own_media, user: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Media)
      assert ability.can?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m)
      assert ability.cannot?(:destroy, own_media)
      assert ability.can?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.can?(:administer_content, pm)
      assert ability.can?(:administer_content, own_pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.cannot?(:destroy, own_pm)
      assert ability.cannot?(:update, m2)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m2)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:update, pm_own)
      assert ability.cannot?(:destroy, pm2)
      assert ability.cannot?(:destroy, pm_own)
    end
  end

  test "editor permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'editor'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    own_pm = create_project_media project: p, media: own_media, user: u
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Media)
      assert ability.can?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m)
      assert ability.cannot?(:destroy, own_media)
      assert ability.can?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.can?(:administer_content, pm)
      assert ability.can?(:administer_content, own_pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.can?(:destroy, own_pm)
      assert ability.cannot?(:update, m2)
      assert ability.cannot?(:destroy, m2)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:destroy, pm2)
    end
  end

  test "owner permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'owner'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    own_pm = create_project_media project: p, media: own_media
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Media)
      assert ability.can?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.can?(:destroy, m)
      assert ability.can?(:destroy, own_media)
      assert ability.can?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.can?(:administer_content, pm)
      assert ability.can?(:administer_content, own_pm)
      assert ability.can?(:destroy, pm)
      assert ability.can?(:destroy, own_pm)
      assert ability.cannot?(:update, m2)
      assert ability.cannot?(:destroy, m2)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:destroy, pm2)
    end
  end

  test "authenticated permissions for team" do
    u = create_user
    t = create_team
    with_current_user_and_team(u, nil) do
      ability = Ability.new
      assert ability.can?(:create, Team)
      assert ability.cannot?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "contributor permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Team)
      assert ability.cannot?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "journalist permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Team)
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
      assert ability.can?(:create, Team)
      assert ability.can?(:update, t)
      assert ability.cannot?(:destroy, t)
      assert ability.cannot?(:update, t2)
      assert ability.cannot?(:destroy, t2)
    end
  end

  test "owner permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'owner'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Team)
      assert ability.can?(:update, t)
      assert ability.can?(:destroy, t)
      assert ability.cannot?(:update, t2)
      assert ability.cannot?(:destroy, t2)
    end
  end

  test "owner only can empty trash" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t , role: 'owner'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:destroy, :trash)
    end
    u2 = create_user
    create_team_user user: u2, team: t , role: 'editor'
    with_current_user_and_team(u2, t) do
      ability = Ability.new
      assert ability.cannot?(:destroy, :trash)
    end
  end

  test "authenticated permissions for teamUser" do
    u = create_user
    tu = create_team_user user: u
    User.current = u
    ability = Ability.new
    assert ability.can?(:create, TeamUser)
    assert ability.cannot?(:update, tu)
    assert ability.can?(:destroy, tu)
  end

  test "contributor permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    tu2 = create_team_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
      assert ability.cannot?(:update, tu)
      assert ability.can?(:destroy, tu)
      assert ability.cannot?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
    end
  end

  test "journalist permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    tu2 = create_team_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
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
    tu2 = create_team_user team: t, role: 'contributor'
    tu_other = create_team_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
      assert ability.can?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)

      tu2.update_column(:role, 'owner')

      assert ability.cannot?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
      assert ability.cannot?(:update, tu_other)
      assert ability.cannot?(:destroy, tu_other)
    end
  end

  test "owner permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    u2 = create_user
    tu2 = create_team_user team: t, role: 'editor'
    tu_other = create_team_user

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
      assert ability.can?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
      assert ability.cannot?(:update, tu_other)
      assert ability.cannot?(:destroy, tu_other)
    end
  end

  test "authenticated permissions for contact" do
    u = create_user
    c = create_contact

    with_current_user_and_team(u, nil) do
      ability = Ability.new
      assert ability.cannot?(:create, Contact)
      assert ability.cannot?(:update, c)
      assert ability.cannot?(:destroy, c)
    end
  end

  test "contributor permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    c = create_contact team: t

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, Contact)
      assert ability.cannot?(:update, c)
      assert ability.cannot?(:destroy, c)
    end
  end

  test "journalist permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    c = create_contact team: t

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, Contact)
      assert ability.cannot?(:update, c)
      assert ability.cannot?(:destroy, c)
    end
  end

  test "editor permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    c = create_contact team: t
    c1 = create_contact

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Contact)
      assert ability.can?(:update, c)
      assert ability.cannot?(:destroy, c)
      assert ability.cannot?(:update, c1)
    end
  end

  test "owner permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    c = create_contact team: t
    c1 = create_contact

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Contact)
      assert ability.can?(:update, c)
      assert ability.can?(:destroy, c)
      assert ability.cannot?(:update, c1)
      assert ability.cannot?(:destroy, c1)
    end
  end

  test "contributor permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    u_test1 = create_user
    tu_test1 = create_team_user user: u_test1, role: 'owner'
    u_test2 = create_user
    tu_test2 = create_team_user team: t, user: u_test2, role: 'editor'
    u_test3 = create_user
    tu_test3 = create_team_user team: t, user: u_test3, role: 'journalist'

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

  test "journalist permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    u_test1 = create_user
    tu_test1 = create_team_user team: t, user: u_test1, role: 'owner'
    u_test2 = create_user
    tu_test2 = create_team_user team: t, user: u_test2, role: 'editor'
    u_test3 = create_user
    tu_test3 = create_team_user team: t, user: u_test3, role: 'contributor'

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
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    u_test1 = create_user
    tu_test1 = create_team_user team: t, user: u_test1, role: 'owner'
    u_test2 = create_user
    tu_test2 = create_team_user team: t, user: u_test2, role: 'journalist'
    u_test3 = create_user
    tu_test3 = create_team_user team: t, user: u_test3, role: 'contributor'

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

  test "owner permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    u_test1 = create_user
    tu_test1 = create_team_user team: t, user: u_test1, role: 'editor'

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, u)
      assert ability.can?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      tu_test1.update_column(:role, 'journalist')

      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      tu_test1.update_column(:role, 'contributor')

      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      assert ability.cannot?(:update, u2_test)
      assert ability.cannot?(:destroy, u2_test)
    end
  end

  test "contributor permissions for comment" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc
    own_comment = create_comment annotator: u
    pm.add_annotation own_comment

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Comment)
      assert ability.cannot?(:update, mc)
      assert ability.cannot?(:destroy, mc)
      assert ability.can?(:update, own_comment)
      assert ability.can?(:destroy, own_comment)
    end
  end

  test "journalist permissions for comment" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc
    own_comment = create_comment annotator: u
    pm.add_annotation own_comment

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Comment)
      assert ability.cannot?(:update, mc)
      assert ability.cannot?(:destroy, mc)
      assert ability.can?(:update, own_comment)
      assert ability.can?(:destroy, own_comment)
    end
  end

  test "editor permissions for comment" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Comment)
      assert ability.can?(:update, mc)
      assert ability.can?(:destroy, mc)
    end
  end

  test "owner permissions for comment" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Comment)
      assert ability.can?(:update, mc)
      assert ability.can?(:destroy, mc)
    end
  end

  test "check annotation permissions" do
    # test the create/update/destroy operations
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm

    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        c.save
      end
    end

    tu.role = 'owner'; tu.save!

    with_current_user_and_team(u, create_team) do
      assert_raise RuntimeError do
        c.save
      end
    end

    Rails.cache.clear
    u = User.find(u.id)
    c.text = 'for testing';c.save!
    assert_equal c.text, 'for testing'

    with_current_user_and_team(u, t) do
      assert_nothing_raised RuntimeError do
        c.destroy
      end
    end
  end

  test "owner permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Mark as graphic', annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, f)
      f.flag = 'Graphic content'
      assert ability.can?(:create, f)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, f)
    end
  end

  test "contributor permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Spam', annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, f)
      f.flag = 'Graphic content'
      assert ability.can?(:create, f)
      f.flag = 'Needing deletion'
      assert ability.cannot?(:create, f)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, f)
    end
  end

  test "contributor permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s =  create_status status: 'verified', annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:update, s)
      assert ability.cannot?(:destroy, s)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "journalist permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    t2 = create_team
    p = create_project team: t, user: u
    pm = create_project_media project: p
    s =  create_status status: 'verified', annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, s)
      assert ability.can?(:update, s)
      assert ability.cannot?(:destroy, s)
      Rails.cache.clear
      p.update_column(:team_id, t2.id)
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "editor permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s =  create_status status: 'verified', annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, s)
      assert ability.can?(:update, s)
      assert ability.cannot?(:destroy, s)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "owner permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s = create_status status: 'verified', annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, s)
      assert ability.can?(:update, s)
      assert ability.can?(:destroy, s)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "owner permissions for embed" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    em = create_metadata annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, em)
      assert ability.can?(:update, em)
      assert ability.can?(:destroy, em)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:destroy, em)
    end
  end

  test "contributor permissions for tag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p, user: u
    tg = create_tag tag: 'media_tag', annotator: u, annotated: pm
    u2 = create_user

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
      pm.update_column(:user_id, u2.id)
      Rails.cache.clear
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:destroy, tg)
    end
  end

  test "journalist permissions for tag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    t2 = create_team
    p = create_project team: t, user: u
    pm = create_project_media project: p
    tg = create_tag tag: 'media_tag', context: p, annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
      Rails.cache.clear
      p.update_column(:team_id, t2.id)
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:destroy, tg)
    end
  end

  test "editor permissions for tag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag tag: 'media_tag', annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:destroy, tg)
    end
  end

  test "owner permissions for tag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag tag: 'media_tag', annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:destroy, tg)
    end
  end

  test "read ability for user in public team" do
    u = create_user
    t1 = create_team
    tu = create_team_user user: u , team: t1
    t2 = create_team private: true
    pa = create_project team: t1
    pb = create_project team: t2
    m = create_valid_media
    pma = create_project_media project: pa, media: m
    pmb = create_project_media project: pb, media: m
    c1 = create_comment annotated: pma
    c2 = create_comment annotated: pmb

    with_current_user_and_team(u, t1) do
      ability = Ability.new
      assert ability.can?(:read, t1)
      assert ability.cannot?(:read, t2)
      assert ability.can?(:read, pa)
      assert ability.cannot?(:read, pb)
      assert ability.can?(:read, m)
      assert ability.can?(:read, c1)
      assert ability.cannot?(:read, c2)
    end
  end

  test "read ability for user in private team with member status" do
    u = create_user
    t1 = create_team
    t2 = create_team private: true
    tu = create_team_user user: u , team: t2
    pa = create_project team: t1
    pb = create_project team: t2
    m = create_valid_media
    pma = create_project_media project: pa, media: m
    pmb = create_project_media project: pb, media: m
    c1 = create_comment annotated: pma
    c2 = create_comment annotated: pmb
    with_current_user_and_team(u, tu) do
      ability = Ability.new
      assert ability.can?(:read, t1)
      assert ability.can?(:read, t2)
      assert ability.can?(:read, pa)
      assert ability.can?(:read, pb)
      assert ability.can?(:read, m)
      assert ability.can?(:read, c1)
      assert ability.can?(:read, c2)
    end
  end

  test "read ability for user in private team with non member status" do
    u = create_user
    t1 = create_team
    t2 = create_team private: true
    tu = create_team_user user: u , team: t2, status: 'banned'
    pa = create_project team: t1
    pb = create_project team: t2
    m = create_valid_media
    pma = create_project_media project: pa, media: m
    pmb = create_project_media project: pb, media: m
    c1 = create_comment annotated: pma
    c2 = create_comment annotated: pmb

    with_current_user_and_team(u, t2) do
      ability = Ability.new
      assert ability.can?(:read, t1)
      assert ability.cannot?(:read, t2)
      assert ability.can?(:read, pa)
      assert ability.cannot?(:read, pb)
      assert ability.can?(:read, m)
      assert ability.can?(:read, c1)
      assert ability.cannot?(:read, c2)
    end
  end

  test "only admin users can manage all" do
    u = create_user
    u.is_admin = true
    u.save
    ability = Ability.new(u)
    assert ability.can?(:manage, :all)
  end

  test "admins can do anything" do
    u = create_user
    u.is_admin = true
    u.save
    t = create_team
    tu = create_team_user user: u , team: t
    p = create_project team: t
    own_project = create_project team: t, user: u
    p2 = create_project

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Project)
      assert ability.can?(:update, p)
      assert ability.can?(:update, own_project)
      assert ability.can?(:destroy, p)
      assert ability.can?(:destroy, own_project)
      assert ability.can?(:update, p2)
      assert ability.can?(:destroy, p2)
    end
  end

  test "editor permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Mark as graphic', annotator: u, annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, f)
      assert ability.can?(:destroy, f)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:update, f)
      assert ability.cannot?(:destroy, f)
    end
  end

  test "journalist permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Mark as graphic', annotator: u, annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, f)
      assert ability.cannot?(:destroy, f)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:update, f)
      assert ability.cannot?(:destroy, f)
    end
  end

  test "contributor permissions for project source" do
    u = create_user
    t = create_team
    s = create_source user: u
    tu = create_team_user user: u , team: t, role: 'contributor'
    p1 = create_project team: t
    p2 = create_project
    p3 = create_project team: t
    ps1 = create_project_source project: p1
    ps2 = create_project_source project: p2
    ps3 = create_project_source project: p3, source: s
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, ps1)
      assert ability.cannot?(:update, ps1)
      assert ability.cannot?(:destroy, ps1)
      assert ability.cannot?(:create, ps2)
      assert ability.cannot?(:update, ps2)
      assert ability.cannot?(:destroy, ps2)
      assert ability.can?(:create, ps3)
      assert ability.can?(:update, ps3)
      assert ability.cannot?(:destroy, ps3)
    end
  end

  test "journalist permissions for account source" do
    u = create_user
    u2 = create_user
    t = create_team
    t2 = create_team
    a = create_valid_account
    own_s = create_source user: u, team: t
    s = create_source user: u2, team: t
    s2 = create_source user: u, team: t2
    tu = create_team_user user: u , team: t, role: 'journalist'
    as = create_account_source source: s, account: a
    own_as = create_account_source source: own_s, account: a
    as2 = create_account_source source: s2, account: a
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, own_s)
      assert ability.can?(:update, own_as)
      assert ability.cannot?(:destroy, own_as)
      assert ability.can?(:update, as)
      assert ability.cannot?(:destroy, as)
      assert ability.cannot?(:update, as2)
      assert ability.cannot?(:destroy, as2)
    end
  end

  test "editor permissions for account source" do
    u = create_user
    u2 = create_user
    t = create_team
    t2 = create_team
    a = create_valid_account
    own_s = create_source user: u, team: t
    s = create_source user: u2, team: t
    s2 = create_source user: u, team: t2
    tu = create_team_user user: u , team: t, role: 'editor'
    as = create_account_source source: s, account: a
    own_as = create_account_source source: own_s, account: a
    as2 = create_account_source source: s2, account: a
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, own_s)
      assert ability.can?(:update, own_as)
      assert ability.cannot?(:destroy, own_as)
      assert ability.can?(:update, as)
      assert ability.cannot?(:destroy, as)
      assert ability.cannot?(:update, as2)
      assert ability.cannot?(:destroy, as2)
    end
  end

  test "owner permissions for account source" do
    u = create_user
    u2 = create_user
    t = create_team
    t2 = create_team
    a = create_valid_account
    own_s = create_source user: u, team: t
    s = create_source user: u2, team: t
    s2 = create_source user: u, team: t2
    tu = create_team_user user: u , team: t, role: 'owner'
    as = create_account_source source: s, account: a
    own_as = create_account_source source: own_s, account: a
    as2 = create_account_source source: s2, account: a
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, own_s)
      assert ability.can?(:update, own_as)
      assert ability.can?(:destroy, own_as)
      assert ability.can?(:update, as)
      assert ability.can?(:destroy, as)
      assert ability.cannot?(:update, as2)
      assert ability.cannot?(:destroy, as2)
    end
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t
    a = create_account

    with_current_user_and_team(u, t) do
      assert_equal ["create TagText", "read Team", "update Team", "destroy Team", "empty Trash", "create Project", "create Account", "create TeamUser", "create User", "create Contact", "invite Members"].sort, JSON.parse(t.permissions).keys.sort
      assert_equal ["read Project", "update Project", "destroy Project", "create ProjectSource", "create Source", "create Media", "create ProjectMedia", "create Claim", "create Link"].sort, JSON.parse(p.permissions).keys.sort
      assert_equal ["read Account", "update Account", "destroy Account", "create Media", "create Link", "create Claim"].sort, JSON.parse(a.permissions).keys.sort
    end
  end

  test "should read source without user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source user: nil
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, s)
    end
  end

  test "should read own source" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source user: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, s)
    end
  end

  test "should not read source from other user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source user: create_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:read, s)
    end
  end

  test "should update own source with or without team" do
    u = create_user
    s = u.source
    User.current = u
    ability = Ability.new
    assert ability.can?(:update, s)
    s.team = create_team;s.save;s.reload
    assert ability.can?(:update, s)
  end

  test "should owner destroy annotation from any project from his team" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    a1 = create_annotation annotated: pm1
    a2 = create_annotation annotated: pm2
    a3 = create_annotation annotated: create_project_media
    with_current_user_and_team(u, t) do
      a = Ability.new
      assert a.can?(:destroy, a1)
      assert a.can?(:destroy, a2)
      assert a.cannot?(:destroy, a3)
    end
  end

  test "should not editor destroy annotation from any project from his team" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    a1 = create_annotation annotated: pm1
    a2 = create_annotation annotated: pm2
    a3 = create_annotation annotated: create_project_media
    with_current_user_and_team(u, t) do
      a = Ability.new
      assert a.can?(:destroy, a1)
      assert a.can?(:destroy, a2)
      assert a.cannot?(:destroy, a3)
    end
  end

  test "should not journalist destroy annotation from his project only" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'journalist'
    p1 = create_project team: t, current_user: u, user: nil
    p2 = create_project team: t
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    a1 = create_annotation annotated: pm1
    a2 = create_annotation annotated: pm2
    a3 = create_annotation annotated: create_project_media

    with_current_user_and_team(u, t) do
      a = Ability.new
      assert a.cannot?(:destroy, a1)
      assert a.cannot?(:destroy, a2)
      assert a.cannot?(:destroy, a3)
    end
  end

  test "should not contributor destroy annotation from him only" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    a1 = create_annotation annotated: pm1, annotator: u
    a2 = create_annotation annotated: pm1
    a3 = create_annotation annotated: pm2
    a4 = create_annotation
    with_current_user_and_team(u, t) do
      a = Ability.new
      assert a.can?(:destroy, a1)
      assert a.cannot?(:destroy, a2)
      assert a.cannot?(:destroy, a3)
      assert a.cannot?(:destroy, a4)
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

  test "should owner destroy annotation versions" do
    create_verification_status_stuff
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      s = create_status annotated: pm, status: 'verified'
      em = create_metadata annotated: pm
      s_v = s.versions.last
      em_v = em.versions.last
      ability = Ability.new
      # Status versions
      assert ability.can?(:create, s_v)
      assert ability.cannot?(:update, s_v)
      assert ability.can?(:destroy, s_v)
      # Embed versions
      assert ability.can?(:create, em_v)
      assert ability.cannot?(:update, em_v)
      assert ability.can?(:destroy, em_v)
    end
  end

  test "should access rails_admin if user is team owner" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'owner'
    p = create_project team: t

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:access, :rails_admin)
    end
  end

  test "should not access rails_admin if user not team owner or admin" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t
    p = create_project team: t

    %w(contributor journalist editor).each do |role|
      tu.role = role; tu.save!
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert !ability.can?(:access, :rails_admin)
      end
    end
  end

  test "owner permissions for task" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    tk = create_task annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tk)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tk)
    end
  end

  test "editor permissions for task" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    tk = create_task annotator: u, annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tk)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tk)
    end
  end

  test "contributor permissions for task" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    tk = create_task annotated: pm
    create_annotation_type annotation_type: 'response'

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, tk)
      tk.label = 'Changed'
      assert ability.cannot?(:update, tk)
      tk = tk.reload
      tk.response = { annotation_type: 'response', set_fields: {} }.to_json
      assert ability.can?(:update, tk)
    end
  end

  test "annotator permissions" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    tk1 = create_task annotator: u, annotated: pm
    tk2 = create_task annotated: pm

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:destroy, tk1)
      assert ability.can?(:update, tk1)
      assert ability.cannot?(:destroy, tk2)
      assert ability.can?(:update, tk2)
    end
  end

  test "contributor can manage own dynamic fields" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    tk = create_task annotated: pm
    create_annotation_type annotation_type: 'response'
    a1 = create_dynamic_annotation annotation_type: 'response', annotator: u
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

  test "contributor permissions for dynamic annotation" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    da = create_dynamic_annotation annotated: pm
    own_da = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Dynamic)
      assert ability.cannot?(:update, da)
      assert ability.cannot?(:destroy, da)
      assert ability.can?(:update, own_da)
      assert ability.can?(:destroy, own_da)
    end
  end

  test "journalist permissions for dynamic annotation" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    pm = create_project_media project: p
    da = create_dynamic_annotation annotated: pm
    own_da = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Dynamic)
      assert ability.cannot?(:update, da)
      assert ability.cannot?(:destroy, da)
      assert ability.can?(:update, own_da)
      assert ability.can?(:destroy, own_da)
    end
  end

  test "editor permissions for dynamic annotation" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    da = create_dynamic_annotation annotated: pm
    own_da = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Dynamic)
      assert ability.can?(:update, da)
      assert ability.can?(:destroy, da)
      assert ability.can?(:update, own_da)
      assert ability.can?(:destroy, own_da)
    end
  end

  test "owner permissions for dynamic annotation" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    da = create_dynamic_annotation annotated: pm
    own_da = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Dynamic)
      assert ability.can?(:update, da)
      assert ability.can?(:destroy, da)
      assert ability.can?(:update, own_da)
      assert ability.can?(:destroy, own_da)
    end
  end

  test "owner permissions for export project data" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:export_project, Project)
    end
  end

  test "api key read permissions for everything" do
    t = create_team private: true
    p = create_project team: t
    pm = create_project_media project: p
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
    tu = create_team_user team: t, user: u, role: 'owner'
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
    tu = create_team_user team: t, user: u, role: 'owner'
    b = create_bot_user
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, BotUser)
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
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm

    u2 = create_user
    t2 = create_team
    tu2 = create_team_user team: t2, user: u2, role: 'owner'
    p2 = create_project team: t2
    pm2 = create_project_media project: p2
    c2 = create_comment annotated: pm2

    with_current_user_and_team(u2, t2) do
      ability = Ability.new
      assert ability.cannot?(:create, c)
      assert ability.can?(:create, c2)
    end

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, c2)
      assert ability.can?(:create, c)
    end
  end

  test "contributor should not edit, send to trash or destroy report" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:update, pm)
      assert ability.cannot?(:destroy, pm)
    end
  end

  test "journalist should send to trash and edit own report but should not destroy" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    pm = create_project_media project: p
    pm2 = create_project_media project: p
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.can?(:update, pm2)
      assert ability.cannot?(:destroy, pm)
    end
  end

  test "editor should send to trash and edit any report but should not destroy" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    pm2 = create_project_media project: p
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.can?(:update, pm2)
      assert ability.cannot?(:destroy, pm)
    end
  end

  test "owner should edit, send to trash and destroy any report" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p, user: u
    pm2 = create_project_media project: p
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, pm)
      assert ability.can?(:destroy, pm)
      assert ability.can?(:update, pm2)
      assert ability.can?(:destroy, pm)
    end
  end

  test "contributor should edit and destroy own annotation from trash but should not destroy respective log entry" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    c2 = create_comment annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, c)
      assert ability.can?(:destroy, c)
      assert ability.cannot?(:update, c2)
      assert ability.cannot?(:destroy, c2)
      c.destroy!
      v = PaperTrail::Version.last
      assert ability.cannot?(:destroy, v)
    end
  end

  test "journalist should edit and destroy own annotation from trash but should not destroy respective log entry" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    c2 = create_comment annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, c)
      assert ability.can?(:destroy, c)
      assert ability.cannot?(:update, c2)
      assert ability.cannot?(:destroy, c2)
      c.destroy!
      v = PaperTrail::Version.last
      assert ability.cannot?(:destroy, v)
    end
  end

  test "editor should edit own annotation and destroy any annotation from trash but should not destroy respective log entry" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    c2 = create_comment annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, c)
      assert ability.can?(:destroy, c)
      assert ability.can?(:update, c2)
      assert ability.can?(:destroy, c2)
      c.destroy!
      v = PaperTrail::Version.last
      assert ability.cannot?(:destroy, v)
      c2.destroy!
      v = PaperTrail::Version.last
      assert ability.cannot?(:destroy, v)
    end
  end

  test "owner should edit own annotation and destroy any annotation from trash and should destroy respective log entry" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, annotator: u
    c2 = create_comment annotated: pm
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, c)
      assert ability.can?(:destroy, c)
      assert ability.can?(:update, c2)
      assert ability.can?(:destroy, c2)
      c.destroy!
      v = PaperTrail::Version.last
      assert ability.can?(:destroy, v)
      c2.destroy!
      v = PaperTrail::Version.last
      assert ability.can?(:destroy, v)
    end
  end

  test "contributor should not edit, send to trash or destroy project" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor'
    p = create_project team: t, user: u
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:update, p)
      assert ability.cannot?(:destroy, p)
    end
  end

  test "journalist should edit and send to trash but not destroy own project" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t, user: u
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, p)
      assert ability.cannot?(:destroy, p)
      assert ability.cannot?(:update, p2)
      assert ability.cannot?(:destroy, p2)
    end
  end

  test "editor should edit any project and send any project to trash but not destroy project" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t, user: u
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, p)
      assert ability.cannot?(:destroy, p)
      assert ability.can?(:update, p2)
      assert ability.cannot?(:destroy, p2)
    end
  end

  test "owner should edit any project, destroy any project and send any project to trash" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t, user: u
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:update, p)
      assert ability.can?(:destroy, p)
      assert ability.can?(:update, p2)
      assert ability.can?(:destroy, p2)
    end
  end

  test "contributor should not send to trash, edit or destroy team" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:update, t)
      assert ability.cannot?(:destroy, t)
    end
  end

  test "journalist should not send to trash, edit or destroy team" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'journalist'
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

  test "owner should send to trash, edit or destroy own team" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
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

  test "editor should not downgrade owner role" do
    t = create_team
    u = create_user
    u2 = create_user
    u3 = create_user
    tu1 = create_team_user team: t, user: u, role: 'editor'
    tu2 = create_team_user team: t, user: u2, role: 'owner'
    tu2 = TeamUser.find(tu2.id)
    tu3 = create_team_user team: t, user: u3, role: 'contributor'
    tu3 = TeamUser.find(tu3.id)
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        tu3.role = 'journalist'
        tu3.save!
      end

      assert_raises RuntimeError do
        tu2.role = 'editor'
        tu2.save!
      end
    end
  end

  test "journalist permissions for verification status" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'journalist'
    p = create_project team: t, user: u
    pm = create_project_media user: u, project: p
    s = create_status annotated: pm, status: 'verified'
    s2 = create_status annotated: pm, status: 'verified', locked: true
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, s)
      assert ability.can?(:update, s)
      assert ability.cannot?(:destroy, s)
      assert ability.cannot?(:update, s2)
      assert ability.cannot?(:destroy, s2)
    end
  end

  test "contributor permissions for verification status" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'contributor'
    p = create_project team: t, user: u
    pm = create_project_media user: u, project: p
    s = create_status annotated: pm, status: 'verified'
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:update, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "editor permissions for verification status" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'editor'
    p = create_project team: t, user: u
    pm = create_project_media user: u, project: p
    s = create_status annotated: pm, status: 'verified', locked: true
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, s)
      assert ability.can?(:update, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "permissions for annotation type" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    at = create_annotation_type
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:create, DynamicAnnotation::AnnotationType)
      assert ability.cannot?(:update, at)
      assert ability.cannot?(:destroy, at)
    end
  end

  test "permissions for team bot" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u, role: 'owner'
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
    create_team_user team: t1, user: u, role: 'owner'
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
    tu1 = create_team_bot bot_user_id: nil, team_author_id: t1.id
    bu1 = tu1.bot_user

    t2 = create_team private: true
    tu2 = create_team_bot bot_user_id: nil, team_author_id: t2.id
    bu2 = tu2.bot_user

    t3 = create_team private: true
    tu3 = create_team_bot bot_user_id: nil, team_author_id: t3.id
    bu3 = tu3.bot_user

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
    tb1 = create_team_bot approved: false
    tb2 = create_team_bot approved: true
    tb3 = create_team_bot approved: false, team_author_id: t.id

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:read, tb1)
      assert ability.can?(:read, tb2)
      assert ability.can?(:read, tb3)
    end
  end

  test "permissions for tag text" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u, role: 'owner'
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

    ['contributor', 'journalist', 'editor'].each do |role|
      u = create_user
      create_team_user team: t1, user: u, role: role
      ta1 = create_tag_text team_id: t1.id
      with_current_user_and_team(u, t1) do
        ability = Ability.new
        assert ability.cannot?(:create, ta1)
        assert ability.cannot?(:update, ta1)
        assert ability.cannot?(:destroy, ta1)
      end
    end
  end

  test "permissions for assignment" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media project: p
    c = create_comment annotated: pm
    c.assign_user(u.id)
    a = c.assignments.last

    t2 = create_team
    p2 = create_project team: t2
    u2 = create_user
    create_team_user team: t2, user: u2
    pm2 = create_project_media project: p2
    c2 = create_comment annotated: pm2
    c2.assign_user(u2.id)
    a2 = c2.assignments.last

    # Owner and editor: can only assign/unassign annotations of same team
    ['owner', 'editor'].each do |role|
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

    # Journalist and contributor: can only assign/unassign own annotations
    ['journalist', 'contributor'].each do |role|
      u = create_user
      create_team_user team_id: t.id, user_id: u.id, role: role
      c3 = create_comment annotated: pm, annotator: u
      c3.assign_user(u.id)
      a3 = c3.assignments.last
      with_current_user_and_team(u, t) do
        ability = Ability.new
        assert ability.cannot?(:destroy, a)
        assert ability.cannot?(:create, a)
        assert ability.cannot?(:destroy, a2)
        assert ability.cannot?(:create, a2)
        assert ability.can?(:destroy, a3)
        assert ability.can?(:create, a3)
      end
    end
  end

  test "admin permissions for import spreadsheet" do
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

  test "team owner and editor can import spreadsheet" do
    t1 = create_team
    t2 = create_team
    u1 = create_user
    create_team_user team: t1, user: u1, role: 'owner'
    create_team_user team: t2, user: u1, role: 'editor'
    with_current_user_and_team(u1, t1) do
      ability = Ability.new
      assert ability.can?(:import_spreadsheet, t1)
      assert ability.cannot?(:import_spreadsheet, t2)
    end
    with_current_user_and_team(u1, t2) do
      ability = Ability.new
      assert ability.cannot?(:import_spreadsheet, t1)
      assert ability.can?(:import_spreadsheet, t2)
    end
  end

  test "team contributor and journalist cannot import spreadsheet" do
    t1 = create_team
    t2 = create_team
    u1 = create_user
    create_team_user team: t1, user: u1, role: 'contributor'
    create_team_user team: t2, user: u1, role: 'journalist'
    with_current_user_and_team(u1, t1) do
      ability = Ability.new
      assert ability.cannot?(:import_spreadsheet, t1)
      assert ability.cannot?(:import_spreadsheet, t2)
    end
    with_current_user_and_team(u1, t2) do
      ability = Ability.new
      assert ability.cannot?(:import_spreadsheet, t1)
      assert ability.cannot?(:import_spreadsheet, t2)
    end
  end

  test "annotator permissions for annotation field" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'annotator'
    a = create_dynamic_annotation annotator: u
    f1 = create_field annotation_id: a.id
    f2 = create_field
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, f1)
      assert ability.can?(:manage, f1)
      assert ability.can?(:update, f1)
      assert ability.can?(:destroy, f1)
      assert ability.cannot?(:read, f2)
      assert ability.cannot?(:manage, f2)
      assert ability.cannot?(:update, f2)
      assert ability.cannot?(:destroy, f2)
    end
  end

  test "annotator permissions for project and medias" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'annotator'
    p1 = create_project team: t
    pm1 = create_project_media project: p1
    p2 = create_project team: t
    pm2 = create_project_media project: p2
    create_task annotated: pm2
    tk = create_task annotated: pm1
    tk.assign_user(u.id)
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, p1)
      assert ability.can?(:read, pm1)
      assert ability.cannot?(:read, p2)
      assert ability.cannot?(:read, pm2)
    end
  end

  test "should not duplicate query conditions" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'annotator'
    p = create_project team: t
    3.times{ create_project_media(project: p) }
    pmids = []
    3.times do
      pm = create_project_media project: p
      pmids << pm.id
      create_task annotated: pm
      tk = create_task annotated: pm
      tk.assign_user(u.id)
    end
    with_current_user_and_team(u, t) do
      4.times { Ability.new }
      queries = assert_queries do
        ProjectMedia.where(project_id: p.id).permissioned.permissioned.count
      end
      query = "SELECT COUNT(*) FROM \"project_medias\" WHERE \"project_medias\".\"project_id\" = $1 AND \"project_medias\".\"inactive\" = $2 AND \"project_medias\".\"id\" IN (#{pmids[0]}, #{pmids[1]}, #{pmids[2]})"
      assert_equal query, queries.first
    end
  end
end
