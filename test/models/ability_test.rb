require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AbilityTest < ActiveSupport::TestCase

  test "contributor permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'contributor'
    p = create_project
    own_project = create_project(user: u)
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    tu = create_team_user team: t, user: u , role: 'journalist'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    create_project_media project: p, media: own_media
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    assert ability.cannot?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # test medias that related to other instances
    m2 = create_valid_media
    create_project_media media: m2
    own_media = create_valid_media user_id: u.id
    create_project_media media: own_media
    assert ability.cannot?(:update, m2)
    assert ability.cannot?(:update, own_media)
    assert ability.cannot?(:destroy, m2)
    assert ability.cannot?(:destroy, own_media)
  end

  test "journalist permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'journalist'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    create_project_media project: p, media: own_media
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    assert ability.cannot?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # test medias that related to other instances
    m2 = create_valid_media
    create_project_media media: m2
    own_media = create_valid_media user_id: u.id
    create_project_media media: own_media
    assert ability.cannot?(:update, m2)
    assert ability.cannot?(:update, own_media)
    assert ability.cannot?(:destroy, m2)
    assert ability.cannot?(:destroy, own_media)
  end

  test "editor permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'editor'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    create_project_media project: p, media: own_media
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    assert ability.can?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.can?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # test medias that related to other instances
    m2 = create_valid_media
    create_project_media media: m2
    assert ability.cannot?(:update, m2)
    assert ability.cannot?(:destroy, m2)
  end

  test "owner permissions for media" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u , role: 'owner'
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    create_project_media project: p, media: own_media
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    assert ability.can?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.can?(:destroy, m)
    assert ability.can?(:destroy, own_media)
    # test medias that related to other instances
    m2 = create_valid_media
    create_project_media media: m2
    assert ability.cannot?(:update, m2)
    assert ability.cannot?(:destroy, m2)
  end

  test "contributor permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'contributor'
    ability = Ability.new(u)
    assert ability.can?(:create, Team)
    assert ability.cannot?(:update, t)
    assert ability.cannot?(:destroy, t)
  end

  test "journalist permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'journalist'
    ability = Ability.new(u)
    assert ability.can?(:create, Team)
    assert ability.cannot?(:update, t)
    assert ability.cannot?(:destroy, t)
  end

  test "editor permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: 'editor'
    ability = Ability.new(u)
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
    ability = Ability.new(u)
    assert ability.can?(:create, Team)
    assert ability.can?(:update, t)
    assert ability.can?(:destroy, t)
    # test other instances
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'owner'
    assert ability.cannot?(:update, t2)
    assert ability.cannot?(:destroy, t2)

  end

  test "contributor permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.cannot?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    create_team_user team: t, user: u_test , role: 'editor'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    create_team_user team: t, user: u_test , role: 'journalist'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "journalist permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    create_team_user team: t, user: u_test , role: 'editor'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    create_team_user team: t, user: u_test , role: 'contributor'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "editor permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user team: t, user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    u_test = create_user
    create_team_user team: t, user: u_test , role: 'journalist'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    u_test = create_user
    create_team_user team: t, user: u_test , role: 'contributor'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    # tests for other instances
    u2_test = create_user
    create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "owner permissions for user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    ability = Ability.new(u)
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
    create_team_user user: u2_test , role: 'contributor'
    assert ability.cannot?(:update, u2_test)
    assert ability.cannot?(:destroy, u2_test)
  end

  test "contributor permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'contributor'
     ability = Ability.new(u)
     assert ability.can?(:create, Comment)
     # project comments
     p = create_project team: t
     pc = create_comment
     p.add_annotation pc
     assert ability.cannot?(:update, pc)
     assert ability.cannot?(:destory, pc)
     # media comments
     m = create_valid_media
     pm = create_project_media project: p, media: m
     mc = create_comment
     m.add_annotation mc
     assert ability.cannot?(:update, mc)
     assert ability.cannot?(:destory, mc)
     # own comments
     own_comment = create_comment annotator: u
     p2 = create_project team: t, user: u
     p2.add_annotation own_comment
     #pp own_comment
     #assert ability.can?(:update, own_comment)
     #assert ability.can?(:destory, own_comment)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destory, c)
  end

  test "journalist permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'journalist'
     ability = Ability.new(u)
     assert ability.can?(:create, Comment)
     # project comments
     p = create_project team: t
     pc = create_comment
     p.add_annotation pc
     assert ability.cannot?(:update, pc)
     assert ability.cannot?(:destory, pc)
     # media comments
     m = create_valid_media
     pm = create_project_media project: p, media: m
     mc = create_comment
     m.add_annotation mc
     assert ability.cannot?(:update, mc)
     assert ability.cannot?(:destory, mc)
     # own comments
     own_comment = create_comment annotator: u
     p2 = create_project team: t
     p2.add_annotation own_comment
     #assert ability.can?(:update, own_comment)
     #assert ability.can?(:destory, own_comment)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destory, c)
  end

  test "editor permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'editor'
     ability = Ability.new(u)
     assert ability.can?(:create, Comment)
     # project comments
     p = create_project team: t
     pc = create_comment
     p.add_annotation pc
     assert ability.can?(:update, pc)
     assert ability.can?(:destory, pc)
     # media comments
     m = create_valid_media
     pm = create_project_media project: p, media: m
     mc = create_comment
     m.add_annotation mc
     assert ability.can?(:update, mc)
     assert ability.can?(:destory, mc)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destory, c)
  end

  test "owner permissions for comment" do
     u = create_user
     t = create_team
     tu = create_team_user team: t, user: u, role: 'owner'
     ability = Ability.new(u)
     assert ability.can?(:create, Comment)
     # project comments
     p = create_project team: t
     pc = create_comment
     p.add_annotation pc
     assert ability.can?(:update, pc)
     assert ability.can?(:destory, pc)
     # media comments
     m = create_valid_media
     pm = create_project_media project: p, media: m
     mc = create_comment
     m.add_annotation mc
     assert ability.can?(:update, mc)
     assert ability.can?(:destory, mc)
     # other instances
     p = create_project
     c = create_comment
     p.add_annotation c
     assert ability.cannot?(:update, c)
     assert ability.cannot?(:destory, c)
  end

  test "owner permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    ability = Ability.new(u)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f =  create_flag flag: 'Mark as graphic', annotator: u, annotated: m
    assert ability.can?(:create, f)
    f.flag = 'Graphic content'
    assert ability.cannot?(:create, f)
    # test other instances
    p.team = nil
    assert ability.cannot?(:create, f)
  end

  test "editor permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'editor'
    ability = Ability.new(u)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f =  create_flag flag: 'Mark as graphic', annotator: u, annotated: m
    assert ability.can?(:create, f)
    f.flag = 'Graphic content'
    assert ability.cannot?(:create, f)
    # test other instances
    p.team = nil
    assert ability.cannot?(:create, f)
  end

  test "journalist permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    ability = Ability.new(u)
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f =  create_flag flag: 'Mark as graphic', annotator: u, annotated: m
    assert ability.can?(:create, f)
    f.flag = 'Graphic content'
    assert ability.cannot?(:create, f)
    # test other instances
    p.team = nil
    assert ability.cannot?(:create, f)
  end

  test "contributor permissions for flag" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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

  test "check journalist permissions for project" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'journalist'
    p = create_project team: t
    p.current_user = u
    own_project = create_project team:t, user: u
    own_project.current_user = u
    assert_raise RuntimeError do
        p.save!
    end
    assert_raise RuntimeError do
       p.destroy!
    end
    own_project.title = 'Project A'
    own_project.save!
    assert_equal own_project.title, 'Project A'
    assert_nothing_raised RuntimeError do
        own_project.save!
    end
    assert_nothing_raised RuntimeError do
        own_project.destroy!
    end
  end

  test "read ability for user in public team" do
    u = create_user
    t1 = create_team
    tu = create_team_user user: u , team: t1
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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
    ability = Ability.new(u)
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

end
