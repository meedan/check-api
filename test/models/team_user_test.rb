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

  test "should not duplicate team and user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u
    assert_raises ActiveRecord::RecordInvalid do
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

  test "should read team user" do
    u = create_user
    t = create_team current_user: create_user
    tu = t.team_users.last
    pu = create_user
    pt = create_team current_user: pu, private: true
    ptu = pt.team_users.last
    TeamUser.find_if_can(tu.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      TeamUser.find_if_can(ptu.id, u, pt)
    end
    TeamUser.find_if_can(ptu.id, pu, pt)
    ptu.status = 'requested'; ptu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      TeamUser.find_if_can(ptu.id, pu, pt)
    end
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
    tu.current_user = u
    tu.context_team = t
    tu.status = 'member';tu.save!
    assert_equal tu.status, 'member'
    create_team_user team: t, current_user: u, status: 'member', role: 'journalist'
    assert_raise RuntimeError do
      create_team_user team: t, current_user: u, status: 'member', role: 'owner'
    end
  end

  test "should not approve myself" do
    u = create_user
    t = create_team current_user: u
    u2 = create_user
    tu = create_team_user team: t, user: u2, status: 'requested', role: 'journalist', current_user: u2
    # test approve
    assert_raise RuntimeError do
      tu.status = 'member'
      tu.current_user = u2
      tu.save!
    end
  end

  test "should send e-mail to owners when user requests to join" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      create_team_user
    end

    t = create_team
    u = create_user
    create_team_user team: u, user: u, role: 'owner'
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      create_team_user team: t
    end
  end

  test "should send email to requestor when his request is accepted" do
    t = create_team
    u = create_user
    tu = create_team_user team: u, user: u, role: 'contributor', status: 'requested'
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      tu.status = 'member'
      tu.save!
    end
  end

  test "should send email to requestor when his request is rejected" do
    t = create_team
    u = create_user
    tu = create_team_user team: u, user: u, role: 'contributor', status: 'requested'
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      tu.status = 'banned'
      tu.save!
    end
  end

  test "should not send email to requestor when there is no status change" do
    t = create_team
    u = create_user
    tu = create_team_user team: u, user: u, role: 'contributor', status: 'requested'
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      tu.role = 'owner'
      tu.save!
    end
  end

  test "should not downgrade user role" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'owner'
    tu.current_user = u
    tu.context_team = t
    assert_raise RuntimeError do
      tu.role = 'journalist'
      tu.save
    end
  end
end
