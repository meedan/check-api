require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class TeamUserTest < ActiveSupport::TestCase
  test "should create team user" do
    assert_difference 'TeamUser.count' do
      create_team_user
    end
  end

  test "should prevent creating team user with invalid status" do
    tu = create_team_user
    tu.status = "invalid status"
    assert_not tu.save
    tu.status = "banned"
    assert tu.save
  end

  test "should get user from callback" do
    u = create_user email: 'test@local.com'
    tu = create_team_user
    assert_equal u.id, tu.user_id_callback('test@local.com')
  end

  test "should get team from callback" do
    tu = create_team_user
    assert_equal 2, tu.team_id_callback(1, [1, 2, 3])
  end

  test "should not duplicate team and user [DB validation]" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u
    assert_raises ActiveRecord::RecordNotUnique do
      create_team_user team: t, user: u
    end
  end

 test "should set a default value for role if not exist" do
  tu = create_team_user
  tu.save!
  assert_equal tu.role, 'contributor'
 end

  test "should prevent creating team user with invalid role" do
    tu = create_team_user
    tu.role = "invalid role"
    assert_not tu.save
    tu.role = "owner"
    assert tu.save
  end

  test "should request to join team" do
    u = create_user
    tu = create_team_user user: u, current_user: u, status: 'requested'
    assert_raise RuntimeError do
      tu = create_team_user current_user: u, status: 'requested'
    end
    assert_raise RuntimeError do
      tu = create_team_user user: u, current_user: u, status: 'invited'
    end
  end

  test "should invite and approve users" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    tu = create_team_user team: t, current_user: u, status: 'invited', role: 'contributor'
    assert_raise RuntimeError do
      create_team_user team: t, current_user: u, status: 'invited', role: 'owner'
    end
    # test approve
    tu.status = 'member';tu.save!
    assert_equal tu.status, 'member'
    create_team_user team: t, current_user: u, status: 'member', role: 'journalist'
    assert_raise RuntimeError do
      create_team_user team: t, current_user: u, status: 'member', role: 'owner'
    end
  end

end
