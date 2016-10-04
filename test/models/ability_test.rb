require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AbilityTest < ActiveSupport::TestCase

  test "contributor permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'contributor'
    p = create_project
    own_project = create_project(user: u)
    ability = Ability.new(u, t)
    assert ability.cannot?(:create, Project)
    assert ability.cannot?(:update, p)
    assert ability.cannot?(:update, own_project)
    assert ability.cannot?(:destroy, p)
    assert ability.cannot?(:destroy, own_project)
  end

  test "journalist permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'journalist'
    p = create_project team: t
    own_project = create_project team:t, user: u
    ability = Ability.new(u, t)
    assert ability.can?(:create, Project)
    assert ability.can?(:update, own_project)
    assert ability.can?(:destroy, own_project)
    assert ability.cannot?(:update, p)
    assert ability.cannot?(:destroy, p)
    # test projects that related to other instances
    p2 = create_project user: u
    assert ability.cannot?(:update, p2)
    assert ability.cannot?(:destroy, p2)
  end

  test "editor permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'editor'
    p = create_project team: t
    own_project = create_project team: t, user: u
    ability = Ability.new(u, t)
    assert ability.can?(:create, Project)
    assert ability.can?(:update, p)
    assert ability.can?(:update, own_project)
    assert ability.can?(:destroy, p)
    assert ability.can?(:destroy, own_project)
    # test projects that related to other instances
    p2 = create_project
    assert ability.cannot?(:update, p2)
    assert ability.cannot?(:destroy, p2)
  end

  test "owner permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'owner'
    p = create_project team: t
    own_project = create_project team: t, user: u
    ability = Ability.new(u, t)
    assert ability.can?(:create, Project)
    assert ability.can?(:update, p)
    assert ability.can?(:update, own_project)
    assert ability.can?(:destroy, p)
    assert ability.can?(:destroy, own_project)
    # test projects that related to other instances
    p2 = create_project
    assert ability.cannot?(:update, p2)
    assert ability.cannot?(:destroy, p2)
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
    ability = Ability.new(u, t)
    assert ability.can?(:create, Media)
    assert ability.cannot?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # tests for project media
    assert ability.cannot?(:update, pm)
    assert ability.can?(:update, own_pm)
    assert ability.cannot?(:destroy, pm)
    assert ability.can?(:destroy, own_pm)
    # test medias that related to other instances
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    own_media = create_valid_media user_id: u.id
    pm_own = create_project_media media: own_media
    assert ability.cannot?(:update, m2)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m2)
    assert ability.cannot?(:destroy, own_media)
    # tests for project media
    assert ability.cannot?(:update, pm2)
    assert ability.cannot?(:update, pm_own)
    assert ability.cannot?(:destroy, pm2)
    assert ability.cannot?(:destroy, pm_own)
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
    ability = Ability.new(u, t)
    assert ability.can?(:create, Media)
    assert ability.cannot?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # tests for project media
    assert ability.cannot?(:update, pm)
    assert ability.can?(:update, own_pm)
    assert ability.cannot?(:destroy, pm)
    assert ability.can?(:destroy, own_pm)
    # test medias that related to other instances
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    own_media = create_valid_media user_id: u.id
    pm_own = create_project_media media: own_media
    assert ability.cannot?(:update, m2)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m2)
    assert ability.cannot?(:destroy, own_media)
    # tests for project media
    assert ability.cannot?(:update, pm2)
    assert ability.cannot?(:update, pm_own)
    assert ability.cannot?(:destroy, pm2)
    assert ability.cannot?(:destroy, pm_own)
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
    ability = Ability.new(u, t)
    assert ability.can?(:create, Media)
    assert ability.can?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.can?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # tests for project media
    assert ability.can?(:update, pm)
    assert ability.can?(:update, own_pm)
    assert ability.can?(:destroy, pm)
    assert ability.can?(:destroy, own_pm)
    # test medias that related to other instances
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    assert ability.cannot?(:update, m2)
    assert ability.cannot?(:destroy, m2)
    # tests for project media
    assert ability.cannot?(:update, pm2)
    assert ability.cannot?(:destroy, pm2)
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
    ability = Ability.new(u, t)
    assert ability.can?(:create, Media)
    assert ability.can?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.can?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # tests for project media
    assert ability.can?(:update, pm)
    assert ability.can?(:update, own_pm)
    assert ability.can?(:destroy, pm)
    assert ability.can?(:destroy, own_pm)
    # test medias that related to other instances
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    assert ability.cannot?(:update, m2)
    assert ability.cannot?(:destroy, m2)
    # tests for project media
    assert ability.cannot?(:update, pm2)
    assert ability.cannot?(:destroy, pm2)
  end

  test "authenticated permissions for team" do
    u = create_user
    ability = Ability.new(u, nil)
    assert ability.can?(:create, Team)
    t = create_team
    assert ability.cannot?(:update, t)
    assert ability.cannot?(:destroy, t)
  end

  test "contributor permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    ability = Ability.new(u, t)
    assert ability.can?(:create, Team)
    assert ability.cannot?(:update, t)
    assert ability.cannot?(:destroy, t)
  end

  test "journalist permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    ability = Ability.new(u, t)
    assert ability.can?(:create, Team)
    assert ability.cannot?(:update, t)
    assert ability.cannot?(:destroy, t)
  end

  test "editor permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    ability = Ability.new(u, t)
    assert ability.can?(:create, Team)
    assert ability.can?(:update, t)
    assert ability.cannot?(:destroy, t)
    # test other instances
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'editor'
    assert ability.cannot?(:update, t2)
    assert ability.cannot?(:destroy, t2)
  end

  test "owner permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    ability = Ability.new(u, t)
    assert ability.can?(:create, Team)
    assert ability.can?(:update, t)
    assert ability.can?(:destroy, t)
    # test other instances
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'owner'
    assert ability.cannot?(:update, t2)
    assert ability.cannot?(:destroy, t2)
  end

  test "authenticated permissions for teamUser" do
    u = create_user
    ability = Ability.new(u, nil)
    assert ability.can?(:create, TeamUser)
    tu = create_team_user user: u
    assert ability.cannot?(:update, tu)
    assert ability.cannot?(:destroy, tu)
  end

  test "contributor permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    ability = Ability.new(u, t)
    assert ability.can?(:create, TeamUser)
    assert ability.cannot?(:update, tu)
    assert ability.can?(:destroy, tu)
    tu2 = create_team_user
    assert ability.cannot?(:update, tu2)
    assert ability.cannot?(:destroy, tu2)
  end

  test "journalist permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    ability = Ability.new(u, t)
    assert ability.can?(:create, TeamUser)
    assert ability.cannot?(:update, tu)
    assert ability.can?(:destroy, tu)
    tu2 = create_team_user
    assert ability.cannot?(:update, tu2)
    assert ability.cannot?(:destroy, tu2)
  end

  test "editor permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    ability = Ability.new(u, t)
    assert ability.can?(:create, TeamUser)
    u2 = create_user
    tu2 = create_team_user team: t, role: 'contributor'
    assert ability.can?(:update, tu2)
    assert ability.cannot?(:destroy, tu2)
    tu2.role = 'owner'; tu2.save!
    assert ability.cannot?(:update, tu2)
    assert ability.cannot?(:destroy, tu2)
    # test other instances
    tu_other = create_team_user
    assert ability.cannot?(:update, tu_other)
    assert ability.cannot?(:destroy, tu_other)
  end

  test "owner permissions for teamUser" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    ability = Ability.new(u, t)
    assert ability.can?(:create, TeamUser)
    u2 = create_user
    tu2 = create_team_user team: t, role: 'editor'
    assert ability.can?(:update, tu2)
    assert ability.cannot?(:destroy, tu2)
    # test other instances
    tu_other = create_team_user
    assert ability.cannot?(:update, tu_other)
    assert ability.cannot?(:destroy, tu_other)
  end


  test "authenticated permissions for contact" do
    u = create_user
    ability = Ability.new(u, nil)
    assert ability.cannot?(:create, Contact)
    c = create_contact
    assert ability.cannot?(:update, c)
    assert ability.cannot?(:destroy, c)
  end

  test "contributor permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    ability = Ability.new(u, t)
    c = create_contact team: t
    assert ability.cannot?(:create, Contact)
    assert ability.cannot?(:update, c)
    assert ability.cannot?(:destroy, c)
  end

  test "journalist permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    ability = Ability.new(u, t)
    c = create_contact team: t
    assert ability.cannot?(:create, Contact)
    assert ability.cannot?(:update, c)
    assert ability.cannot?(:destroy, c)
  end

  test "editor permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    ability = Ability.new(u, t)
    c = create_contact team: t
    assert ability.can?(:create, Contact)
    assert ability.can?(:update, c)
    assert ability.cannot?(:destroy, c)
    # test other instances
    c1 = create_contact
    assert ability.cannot?(:update, c1)
  end

  test "owner permissions for contact" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'owner'
    ability = Ability.new(u, t)
    c = create_contact team: t
    assert ability.can?(:create, Contact)
    assert ability.can?(:update, c)
    assert ability.can?(:destroy, c)
    # test other instances
    c1 = create_contact
    assert ability.cannot?(:update, c1)
    assert ability.cannot?(:destroy, c1)
  end

  test "contributor permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    ability = Ability.new(u, t)
    assert ability.can?(:update, u)
    assert ability.cannot?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'editor'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'journalist'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "journalist permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    ability = Ability.new(u, t)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'editor'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'contributor'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "editor permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    ability = Ability.new(u, t)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'journalist'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'contributor'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "owner permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    ability = Ability.new(u, t)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'editor'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    tu_test.role = 'journalist'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    tu_test.role = 'contributor'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "contributor permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'contributor'
     ability = Ability.new(u, t)
     assert ability.can?(:create, Comment)
     # media comments
     m = create_valid_media team: t
     mc = create_comment
     m.add_annotation mc
     assert ability.cannot?(:update, mc)
     assert ability.cannot?(:destroy, mc)
     # own comments
     own_comment = create_comment annotator: u
     m.add_annotation own_comment
     assert ability.can?(:update, own_comment)
     assert ability.can?(:destroy, own_comment)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destroy, c)
  end

  test "journalist permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'journalist'
     ability = Ability.new(u, t)
     assert ability.can?(:create, Comment)
     # media comments
     m = create_valid_media team: t
     mc = create_comment
     m.add_annotation mc
     assert ability.cannot?(:update, mc)
     assert ability.cannot?(:destroy, mc)
     # own comments
     own_comment = create_comment annotator: u
     m.add_annotation own_comment
     assert ability.can?(:update, own_comment)
     assert ability.can?(:destroy, own_comment)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destroy, c)
  end

  test "editor permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'editor'
     ability = Ability.new(u, t)
     assert ability.can?(:create, Comment)
     # media comments
     m = create_valid_media team: t
     mc = create_comment
     m.add_annotation mc
     assert ability.can?(:update, mc)
     assert ability.can?(:destroy, mc)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destroy, c)
  end

  test "owner permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'owner'
     ability = Ability.new(u, t)
     assert ability.can?(:create, Comment)
     # media comments
     m = create_valid_media team: t
     mc = create_comment
     m.add_annotation mc
     assert ability.can?(:update, mc)
     assert ability.can?(:destroy, mc)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destroy, c)
  end

  test "check annotation permissions" do
    # test the create/update/destroy operations
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t
    c = create_comment annotated: p
    c.current_user = u
    assert_raise RuntimeError do
        c.save
    end
    assert_raise RuntimeError do
        c.destroy
    end
    tu.role = 'owner'; tu.save!
    c.current_user = u
    c.context_team = create_team
    assert_raise RuntimeError do
        c.save
    end
    c.context_team = t
    c.text = 'for testing';c.save!
    assert_equal c.text, 'for testing'
    assert_nothing_raised RuntimeError do
        c.destroy
    end
  end

  test "owner permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    ability = Ability.new(u, t)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f =  create_flag flag: 'Mark as graphic', annotator: u, annotated: m
    assert ability.can?(:create, f)
    f.flag = 'Graphic content'
    assert ability.can?(:create, f)
    # test other instances
    p.team = nil; p.save!
    assert ability.cannot?(:create, f)
  end

  test "contributor permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    ability = Ability.new(u, t)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f =  create_flag flag: 'Spam', annotator: u, annotated: m
    assert ability.can?(:create, f)
    f.flag = 'Graphic content'
    assert ability.can?(:create, f)
    f.flag = 'Needing deletion'
    assert ability.cannot?(:create, f)
    # test other instances
    p.team = nil; p.save!
    assert ability.cannot?(:create, f)
  end

  test "contributor permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    ability = Ability.new(u, t)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s =  create_status status: 'Verified', annotator: u, annotated: m
    assert ability.cannot?(:create, s)
    assert ability.cannot?(:update, s)
    assert ability.cannot?(:destroy, s)
    s.annotator = create_user; s.save!
    assert ability.cannot?(:update, s)
    #assert ability.cannot?(:destroy, s)
    # test other instances
    p.team = nil; p.save!
    assert ability.cannot?(:create, s)
    assert ability.cannot?(:destroy, s)
  end

  test "journalist permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    ability = Ability.new(u, t)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s =  create_status status: 'Verified', annotator: u, annotated: m
    #assert ability.can?(:create, s)
    assert ability.cannot?(:update, s)
    #assert ability.can?(:destroy, s)
    s.annotator = create_user; s.save!
    assert ability.cannot?(:update, s)
    assert ability.cannot?(:destroy, s)
    # test other instances
    p.team = nil; p.save!
    assert ability.cannot?(:create, s)
    assert ability.cannot?(:destroy, s)
  end

  test "editor permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    ability = Ability.new(u, t)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s =  create_status status: 'Verified', annotated: m
    assert ability.can?(:create, s)
    assert ability.cannot?(:update, s)
    assert ability.can?(:destroy, s)
    # test other instances
    p.team = nil; p.save!
    assert ability.cannot?(:create, s)
    assert ability.cannot?(:destroy, s)
  end

  test "owner permissions for status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    ability = Ability.new(u, t)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s =  create_status status: 'Verified', annotated: m
    assert ability.can?(:create, s)
    assert ability.cannot?(:update, s)
    assert ability.can?(:destroy, s)
    # test other instances
    p.team = nil; p.save!
    assert ability.cannot?(:create, s)
    assert ability.cannot?(:destroy, s)
  end

  test "read ability for user in public team" do
    u = create_user
    t1 = create_team
    tu = create_team_user user: u , team: t1
    ability = Ability.new(u, t1)
    t2 = create_team private: true
    pa = create_project team: t1
    pb = create_project team: t2
    m = create_valid_media
    create_project_media project: pa, media: m
    create_project_media project: pb, media: m
    c1 = create_comment annotated: m, context: pa
    c2 = create_comment annotated: m, context: pb
    c3 = create_comment annotated: pa
    c4 = create_comment annotated: pb
    assert ability.can?(:read, t1)
    assert ability.cannot?(:read, t2)
    assert ability.can?(:read, pa)
    assert ability.cannot?(:read, pb)
    assert ability.can?(:read, m)
    assert ability.can?(:read, c1)
    assert ability.cannot?(:read, c2)
    assert ability.can?(:read, c3)
    assert ability.cannot?(:read, c4)
  end

  test "read ability for user in private team with memeber status" do
    u = create_user
    t1 = create_team
    t2 = create_team private: true
    tu = create_team_user user: u , team: t2
    ability = Ability.new(u, tu)
    pa = create_project team: t1
    pb = create_project team: t2
    m = create_valid_media
    create_project_media project: pa, media: m
    create_project_media project: pb, media: m
    c1 = create_comment annotated: m, context: pa
    c2 = create_comment annotated: m, context: pb
    c3 = create_comment annotated: pa
    c4 = create_comment annotated: pb
    assert ability.can?(:read, t1)
    assert ability.can?(:read, t2)
    assert ability.can?(:read, pa)
    assert ability.can?(:read, pb)
    assert ability.can?(:read, m)
    assert ability.can?(:read, c1)
    assert ability.can?(:read, c2)
    assert ability.can?(:read, c3)
    assert ability.can?(:read, c4)
  end

  test "read ability for user in private team with non memeber status" do
    u = create_user
    t1 = create_team
    t2 = create_team private: true
    tu = create_team_user user: u , team: t2, status: 'banned'
    ability = Ability.new(u, t2)
    pa = create_project team: t1
    pb = create_project team: t2
    m = create_valid_media
    create_project_media project: pa, media: m
    create_project_media project: pb, media: m
    c1 = create_comment annotated: m, context: pa
    c2 = create_comment annotated: m, context: pb
    c3 = create_comment annotated: pa
    c4 = create_comment annotated: pb
    assert ability.can?(:read, t1)
    assert ability.cannot?(:read, t2)
    assert ability.can?(:read, pa)
    assert ability.cannot?(:read, pb)
    assert ability.can?(:read, m)
    assert ability.can?(:read, c1)
    assert ability.cannot?(:read, c2)
    assert ability.can?(:read, c3)
    assert ability.cannot?(:read, c4)
  end

  test "admins can do anything" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'admin'
    p = create_project team: t
    own_project = create_project team: t, user: u
    ability = Ability.new(u, t)
    assert ability.can?(:create, Project)
    assert ability.can?(:update, p)
    assert ability.can?(:update, own_project)
    assert ability.can?(:destroy, p)
    assert ability.can?(:destroy, own_project)
    p2 = create_project
    assert ability.can?(:update, p2)
    assert ability.can?(:destroy, p2)
  end

  test "editor permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Mark as graphic', annotator: u, annotated: m
    ability = Ability.new(u, t)
    assert ability.can?(:update, f)
    assert ability.can?(:destroy, f)
    p.team = nil; p.save!
    assert ability.cannot?(:update, f)
    assert ability.cannot?(:destroy, f)
  end

  test "journalist permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Mark as graphic', annotator: u, annotated: m
    ability = Ability.new(u, t)
    assert ability.can?(:update, f)
    assert ability.can?(:destroy, f)
    p.team = nil; p.save!
    assert ability.cannot?(:update, f)
    assert ability.cannot?(:destroy, f)
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
    ability = Ability.new(u, t)
    assert ability.cannot?(:create, ps1)
    assert ability.cannot?(:update, ps1)
    assert ability.cannot?(:destroy, ps1)
    assert ability.cannot?(:create, ps2)
    assert ability.cannot?(:update, ps2)
    assert ability.cannot?(:destroy, ps2)
    assert ability.can?(:create, ps3)
    assert ability.can?(:update, ps3)
    assert ability.can?(:destroy, ps3)
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    t.current_user = u
    t.context_team = t
    assert_equal ["read Team", "update Team", "destroy Team", "create Project", "create Account", "create TeamUser", "create User", "create Contact"], JSON.parse(t.permissions).keys
    p  = create_project team: t
    p.current_user = u
    assert_equal ["read Project", "update Project", "destroy Project", "create ProjectSource", "create Source", "create Media", "create ProjectMedia"], JSON.parse(p.permissions).keys
    a = create_account
    a.current_user = u
    assert_equal ["read Account", "update Account", "destroy Account", "create Media"], JSON.parse(a.permissions).keys
  end

  test "should fallback to to find" do
    u = create_user
    assert_equal u, User.find_if_can(u.id, nil, nil)
  end

  test "should read source without user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source user: nil
    ability = Ability.new(u, t)
    assert ability.can?(:read, s)
  end

  test "should read own source" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source user: u
    ability = Ability.new(u, t)
    assert ability.can?(:read, s)
  end

  test "should not read source from other user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source user: create_user
    ability = Ability.new(u, t)
    assert ability.cannot?(:read, s)
  end

  test "should owner destroy annotation from any project from his team" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p1 = create_project team: t
    p2 = create_project team: t
    a1 = create_annotation context: p1
    a2 = create_annotation context: p1
    a3 = create_annotation context: p2
    a4 = create_annotation
    a = Ability.new(u, t)
    assert a.can?(:destroy, a1)
    assert a.can?(:destroy, a2)
    assert a.can?(:destroy, a3)
    assert a.cannot?(:destroy, a4)
  end

  test "should editor destroy annotation from any project from his team" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p1 = create_project team: t
    p2 = create_project team: t
    a1 = create_annotation context: p1
    a2 = create_annotation context: p1
    a3 = create_annotation context: p2
    a4 = create_annotation
    a = Ability.new(u, t)
    assert a.can?(:destroy, a1)
    assert a.can?(:destroy, a2)
    assert a.can?(:destroy, a3)
    assert a.cannot?(:destroy, a4)
  end

  test "should journalist destroy annotation from his project only" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'journalist'
    p1 = create_project team: t, current_user: u, user: nil
    p2 = create_project team: t
    a1 = create_annotation context: p1
    a2 = create_annotation context: p1
    a3 = create_annotation context: p2
    a4 = create_annotation
    a = Ability.new(u, t)
    assert a.can?(:destroy, a1)
    assert a.can?(:destroy, a2)
    assert a.cannot?(:destroy, a3)
    assert a.cannot?(:destroy, a4)
  end

  test "should contributor destroy annotation from him only" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    p1 = create_project team: t
    p2 = create_project team: t
    a1 = create_annotation context: p1, annotator: u
    a2 = create_annotation context: p1
    a3 = create_annotation context: p2
    a4 = create_annotation
    a = Ability.new(u, t)
    assert a.can?(:destroy, a1)
    assert a.cannot?(:destroy, a2)
    assert a.cannot?(:destroy, a3)
    assert a.cannot?(:destroy, a4)
  end

  test "should user destroy own request to join a team" do
    u = create_user
    t = create_team
    tu1 = create_team_user user: u, team: t
    tu2 = create_team_user user: create_user, team: t
    a = Ability.new(u, t)
    assert a.can?(:destroy, tu1)
    assert a.cannot?(:destroy, tu2)
  end
end
