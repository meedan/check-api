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
    tu = create_team_user user: u , role: 'contributor'
    m = create_valid_media
    own_media = create_valid_media(user_id: u.id)
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:update, m)
    assert ability.can?(:destroy, own_media)
    assert ability.cannot?(:destroy, m)
  end

  test "journalist permissions for media" do
    u = create_user
    tu = create_team_user user: u , role: 'journalist'
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    m = create_valid_media
    own_media = create_valid_media(user_id: u.id)
    assert ability.cannot?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.cannot?(:destroy, m)
    assert ability.can?(:destroy, own_media)
  end

  test "editor permissions for media" do
    u = create_user
    tu = create_team_user user: u , role: 'editor'
    m = create_valid_media
    own_media = create_valid_media(user_id: u.id)
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    assert ability.can?(:update, m)
    assert ability.can?(:update, own_media)
    assert ability.can?(:destroy, m)
    assert ability.can?(:destroy, own_media)
  end

  test "anonymous permissions for team" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t , role: ''
    ability = Ability.new(u)
    assert ability.can?(:create, Team)
    assert ability.cannot?(:update, t)
    assert ability.cannot?(:destroy, t)
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

  test "contributor permissions for user and teamUser" do
    u = create_user
    tu = create_team_user user: u, role: 'contributor'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.cannot?(:destroy, u)
    u_test = create_user
    tu_test = create_team_user user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.cannot?(:update, tu_test)
    assert ability.cannot?(:destroy, tu_test)
    tu_test.role = 'editor'
    tu_test.save!
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.cannot?(:update, tu_test)
    assert ability.cannot?(:destroy, tu_test)
    tu_test.role = 'journalist'
    tu_test.save!
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.cannot?(:update, tu_test)
    assert ability.cannot?(:destroy, tu_test)
  end

  test "journalist permissions for user and teamUser" do
    u = create_user
    tu = create_team_user user: u, role: 'journalist'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    #tests for TeamUser model
    assert ability.can?(:update, tu)
    assert ability.can?(:destroy, tu)
    u_test = create_user
    tu_test = create_team_user user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.cannot?(:update, tu_test)
    assert ability.cannot?(:destroy, tu_test)
    tu_test.role = 'editor'
    tu_test.save!
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.cannot?(:update, tu_test)
    assert ability.cannot?(:destroy, tu_test)
    tu_test.role = 'contributor'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.can?(:update, tu_test)
    assert ability.can?(:destroy, tu_test)
  end

  test "editor permissions for user and teamUser" do
    u = create_user
    tu = create_team_user user: u, role: 'editor'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    #tests for TeamUser model
    assert ability.can?(:update, tu)
    assert ability.can?(:destroy, tu)
    u_test = create_user
    tu_test = create_team_user user: u_test , role: 'owner'
    assert ability.cannot?(:update, u_test)
    assert ability.cannot?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.cannot?(:update, tu_test)
    assert ability.cannot?(:destroy, tu_test)
    tu_test.role = 'journalist'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.can?(:update, tu_test)
    assert ability.can?(:destroy, tu_test)
    tu_test.role = 'contributor'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.can?(:update, tu_test)
    assert ability.can?(:destroy, tu_test)
  end

  test "owner permissions for user and teamUser" do
    u = create_user
    tu = create_team_user user: u, role: 'owner'
    ability = Ability.new(u)
    assert ability.can?(:update, u)
    assert ability.can?(:destroy, u)
    #tests for TeamUser model
    assert ability.can?(:update, tu)
    assert ability.can?(:destroy, tu)
    u_test = create_user
    tu_test = create_team_user user: u_test , role: 'editor'
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.can?(:update, tu_test)
    assert ability.can?(:destroy, tu_test)
    tu_test.role = 'journalist'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.can?(:update, tu_test)
    assert ability.can?(:destroy, tu_test)
    tu_test.role = 'contributor'
    tu_test.save!
    assert ability.can?(:update, u_test)
    assert ability.can?(:destroy, u_test)
    #tests for TeamUser model
    assert ability.can?(:update, tu_test)
    assert ability.can?(:destroy, tu_test)
  end

  test "contributor permissions for source" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'contributor'
    ability = Ability.new(u)
    assert ability.can?(:create, Source)
    s = create_source
    assert !ability.can?(:update, s)
    own_source = create_source(user_id: u.id)
    #assert ability.can?(:update, own_source)
    assert !ability.can?(:destroy, s)
    assert !ability.can?(:destroy, own_source)
  end

  test "journalist permissions for source" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'journalist'
    ability = Ability.new(u)
    assert ability.can?(:create, Source)
    s = create_source
    assert !ability.can?(:update, s)
    own_source = create_source(user_id: u.id)
    #assert ability.can?(:update, own_source)
    assert !ability.can?(:destroy, s)
    assert !ability.can?(:destroy, own_source)
  end

  test "editor permissions for source" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'editor'
    ability = Ability.new(u)
    assert ability.can?(:create, Source)
    s = create_source
    assert ability.can?(:update, s)
    own_source = create_source(user_id: u.id)
    assert ability.can?(:update, own_source)
    assert ability.can?(:destroy, s)
    assert ability.can?(:destroy, own_source)
  end

  test "contributor permissions for account" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'contributor'
    ability = Ability.new(u)
    assert ability.can?(:create, Account)
    a = create_valid_account
    assert !ability.can?(:update, a)
    own_account = create_valid_account(user_id: u.id)
    assert ability.can?(:update, own_account)
    assert !ability.can?(:destroy, a)
    assert !ability.can?(:destroy, own_account)
  end

  test "journalist permissions for account" do
    u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'journalist'
    ability = Ability.new(u)
    assert ability.can?(:create, Account)
    a = create_valid_account
    assert !ability.can?(:update, a)
    own_account = create_valid_account(user_id: u.id)
    assert ability.can?(:update, own_account)
    assert !ability.can?(:destroy, a)
    assert !ability.can?(:destroy, own_account)
  end

  test "editor permissions for account" do
   u = create_user
    t = create_team
    tu = create_team_user user: u , team: t, role: 'editor'
    ability = Ability.new(u)
    assert ability.can?(:create, Account)
    a = create_valid_account
    assert ability.can?(:update, a)
    own_account = create_valid_account(user_id: u.id)
    assert ability.can?(:update, own_account)
    assert ability.can?(:destroy, a)
    assert ability.can?(:destroy, own_account)
  end

end
