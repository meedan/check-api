require_relative '../test_helper'

class TeamUserTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

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

  test "non members should not read team user in private team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: create_user, role: 'owner'
    tu = t.team_users.last
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu, role: 'owner'
    ptu = pt.team_users.last

    with_current_user_and_team(u, t) { TeamUser.find_if_can(tu.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { TeamUser.find_if_can(ptu.id) }
    end
    with_current_user_and_team(pu, pt) { TeamUser.find_if_can(ptu.id) }
    ptu.status = 'requested'; ptu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu.reload, pt) { TeamUser.find_if_can(ptu.reload.id) }
    end
  end

  test "should request to join team" do
    TeamUser.delete_all
    u = create_user
    t = create_team
    t2 = create_team
    with_current_user_and_team(u, t) do
      tu = create_team_user user: u, status: 'requested', team: t
      assert_raise RuntimeError do
        tu = create_team_user status: 'requested', team: t, user: create_user
      end
      assert_raise RuntimeError do
        tu = create_team_user user: u, status: 'invited', team: t2
      end
    end
  end

  test "should invite and approve users" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'

    with_current_user_and_team(u, t) do
      tu = create_team_user team: t, status: 'invited', role: 'contributor'
      assert_raise RuntimeError do
        create_team_user team: t, status: 'invited', role: 'owner'
      end
      tu.status = 'member'; tu.save!
      assert_equal tu.status, 'member'
      create_team_user team: t, status: 'member', role: 'journalist'
      assert_raise RuntimeError do
        create_team_user team: t, status: 'member', role: 'owner'
      end
    end
  end

  test "should not approve myself" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    u2 = create_user
    tu = create_team_user team: t, user: u2, status: 'requested', role: 'journalist'

    with_current_user_and_team(u2, t) do
      assert_raise RuntimeError do
        tu.status = 'member'
        tu.save!
      end
    end
  end

  test "should send e-mail to owners when user requests to join" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    u2 = create_user
    assert_difference 'MailWorker.jobs.size', 1 do
      create_team_user team: t, user: u2, status: 'requested'
    end
  end

  test "should send email to requestor when his request is accepted" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor', status: 'requested'
    assert_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size', 1 do
      tu.status = 'member'
      tu.save!
    end
  end

  test "should send email to requestor when his request is rejected" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor', status: 'requested'
    assert_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size', 1 do
      tu.status = 'banned'
      tu.save!
    end
  end

  test "should not send email to requestor when there is no status change" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'contributor', status: 'requested'
    assert_no_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size' do
      tu.role = 'owner'
      tu.save!
    end
  end

  test "should not downgrade higher roles" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'owner'

    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        tu.role = 'journalist'
        tu.save
      end
    end
  end

  test "should not change own role" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    u2 = create_user
    tu2 = create_team_user team: t, user: u2, role: 'owner'

    assert_nothing_raised RuntimeError do
      with_current_user_and_team(u, t) do
        tu2.role = 'editor'
        tu2.save!
      end
    end

    u3 = create_user
    tu3 = create_team_user team: t, user: u3, role: 'journalist'
    assert_raise RuntimeError do
      with_current_user_and_team(u3, t) do
        tu.role = 'editor'
        tu.save!
      end
    end
  end

  test "should notify Slack when user joins team" do
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user({ is_admin: true })
    with_current_user_and_team(u, t) do
      tu = create_team_user team: t, user: u, status: 'member'
      assert tu.sent_to_slack

      tu = TeamUser.find(tu.id)
      tu.role = 'editor'
      tu.save!
      assert_not tu.sent_to_slack

      tu = TeamUser.find(tu.id)
      tu.status = 'invited'
      tu.save!
      assert tu.sent_to_slack
    end
  end

  test "should take :slack_teams setting into account" do
    t1 = create_team slug: 'test1'
    t2 = create_team slug: 'test2'
    t2.set_slack_teams = { 'SlackTeamID' => 'SlackTeamName' }
    t2.save!
    t2.reload
    u1 = create_user
    u2 = create_omniauth_user provider: 'twitter'
    u3 = create_omniauth_user provider: 'slack'
    u4 = create_omniauth_user provider: 'slack', info: { 'team_id' => 'SlackTeamID' }
    u5 = create_omniauth_user provider: 'slack', info: { 'team_id' => 'OtherSlackTeamID' }
    User.current = nil
    assert_nothing_raised do
      create_team_user team: t1, user: u1
    end
    assert_nothing_raised do
      create_team_user team: t1, user: u2
    end
    assert_nothing_raised do
      create_team_user team: t1, user: u3
    end
    assert_nothing_raised do
      create_team_user team: t1, user: u4
    end
    assert_nothing_raised do
      create_team_user team: t1, user: u5
    end
    assert_nothing_raised do
      create_team_user team: t2, user: u1
    end
    assert_nothing_raised do
      create_team_user team: t2, user: u2
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team_user team: t2, user: u3
    end
    assert_nothing_raised do
      create_team_user team: t2, user: u4
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_team_user team: t2, user: u5
    end
  end

  test "should auto-approve slack users" do
    t = create_team slug: 'slack'
    t.set_slack_teams = { 'SlackTeamID' => 'SlackTeamName' }
    t.save
    u = create_omniauth_user provider: 'slack', 'info': { 'team_id' => 'SlackTeamID' }
    tu = create_team_user team: t, user: u
    assert_equal 'member', tu.status
    assert_equal 'contributor', tu.role
  end

  test "should protect attributes from mass assignment" do
    raw_params = { user: create_user, team: create_team }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      TeamUser.create(params)
    end
  end

  test "should update teams cache when team user is created, updated or deleted" do
    t = create_team
    u = create_user
    assert_equal [], u.reload.cached_teams
    tu = create_team_user team: t, user: u, status: 'requested'
    assert_equal [], u.reload.cached_teams
    tu.status = 'member'
    tu.save!
    assert_equal [t.id], u.reload.cached_teams
    tu.status = 'banned'
    tu.save!
    assert_equal [], u.reload.cached_teams
    tu.status = 'member'
    tu.save!
    assert_equal [t.id], u.reload.cached_teams
    tu.destroy
    assert_equal [], u.reload.cached_teams
  end

  test "should not create team user if limit was reached" do
    t = create_team
    t.set_max_number_of_members 5
    t.save!
    t = Team.find(t.id)
    create_team_user team_id: t.id, user_id: create_user.id
    4.times do
      create_team_user team_id: t.id, user_id: create_user.id
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_team_user team_id: t.id, user_id: create_user.id
    end
  end

end
