require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AbilityTest < ActiveSupport::TestCase

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
    own_pm = create_project_media project: p, media: own_media
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    own_media = create_valid_media user_id: u.id
    pm_own = create_project_media media: own_media
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Media)
      assert ability.cannot?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m)
      assert ability.cannot?(:destroy, own_media)
      assert ability.cannot?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.can?(:destroy, own_pm)
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
    own_pm = create_project_media project: p, media: own_media
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    pm_own = create_project_media media: own_media
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, Media)
      assert ability.can?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.cannot?(:destroy, m)
      assert ability.cannot?(:destroy, own_media)
      assert ability.cannot?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.cannot?(:destroy, pm)
      assert ability.can?(:destroy, own_pm)
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
    own_pm = create_project_media project: p, media: own_media
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

  test "authenticated permissions for teamUser" do
    u = create_user
    tu = create_team_user user: u
    with_current_user_and_team(u, nil) do
      ability = Ability.new
      assert ability.can?(:create, TeamUser)
      assert ability.cannot?(:update, tu)
      assert ability.can?(:destroy, tu)
    end
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
      assert ability.cannot?(:destroy, u)
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
      assert ability.cannot?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)
      assert ability.cannot?(:update, u_test2)
      assert ability.cannot?(:destroy, u_test2)
      assert ability.can?(:update, u_test3)
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
      assert ability.cannot?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)
      assert ability.can?(:update, u_test2)
      assert ability.cannot?(:destroy, u_test2)
      assert ability.can?(:update, u_test3)
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
      assert ability.can?(:update, u_test1)
      assert ability.can?(:destroy, u_test1)

      tu_test1.update_column(:role, 'journalist')

      assert ability.can?(:update, u_test1)
      assert ability.can?(:destroy, u_test1)

      tu_test1.update_column(:role, 'contributor')

      assert ability.can?(:update, u_test1)
      assert ability.can?(:destroy, u_test1)

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
      assert ability.cannot?(:destroy, own_comment)
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
      assert ability.cannot?(:destroy, own_comment)
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
      assert ability.cannot?(:destroy, mc)
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
      assert_raise RuntimeError do
        c.destroy
      end
    end

    tu.role = 'owner'; tu.save!

    with_current_user_and_team(u, create_team) do
      assert_raise RuntimeError do
        c.save
      end
    end

    Rails.cache.clear
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
      assert ability.cannot?(:update, s)
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
      assert ability.cannot?(:update, s)
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
      assert ability.cannot?(:update, s)
      assert ability.can?(:destroy, s)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:destroy, s)
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

  test "admins can do anything" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'admin'
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
      assert ability.cannot?(:destroy, f)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:update, f)
      assert ability.cannot?(:destroy, f)
    end
  end

  test "journalist permissions for flag" do
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

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t
    a = create_account

    with_current_user_and_team(u, t) do
      assert_equal ["read Team", "update Team", "destroy Team", "create Project", "create Account", "create TeamUser", "create User", "create Contact"], JSON.parse(t.permissions).keys
      assert_equal ["read Project", "update Project", "destroy Project", "create ProjectSource", "create Source", "create Media", "create ProjectMedia"], JSON.parse(p.permissions).keys
      assert_equal ["read Account", "update Account", "destroy Account", "create Media"], JSON.parse(a.permissions).keys
    end
  end

  test "should fallback to find" do
    u = create_user
    assert_equal u, User.find_if_can(u.id)
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
      assert a.cannot?(:destroy, a1)
      assert a.cannot?(:destroy, a2)
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
      assert a.cannot?(:destroy, a1)
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

  test "should be able to tag source" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    s = create_source user: u
    tg = create_tag tag: 'tag', annotator: u, annotated: s

    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:create, tg)
    end
  end
end
