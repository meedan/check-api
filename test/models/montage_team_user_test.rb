require_relative '../test_helper'

class MontageTeamUserTest < ActiveSupport::TestCase
  test "should return if user is admin/owner" do
    t = create_team
    u = create_user
    u2 = create_user
    tu = create_team_user(team: t, user: u, status: 'member', role: 'owner').extend(Montage::ProjectUser)
    assert tu.is_admin
    assert tu.is_owner
    tu = create_team_user(team: t, user: u2, status: 'member', role: 'journalist').extend(Montage::ProjectUser)
    assert !tu.is_admin
    assert !tu.is_owner
  end

  test "should return if user is assigned or pending" do
    t = create_team
    u = create_user
    tu = create_team_user(team: t, user: u, status: 'requested', role: 'journalist').extend(Montage::ProjectUser)
    assert tu.is_pending
    assert !tu.is_assigned
    tu.status = 'member'
    tu.save!
    assert !tu.is_pending
    assert tu.is_assigned
  end

  test "should return the last time that the updates were viewed" do
    t = create_team
    u = create_user
    tu = create_team_user(team: t, user: u).extend(Montage::ProjectUser)
    assert_kind_of String, tu.last_updates_viewed
  end

  test "should return user information as a hash" do
    t = create_team
    u = create_user
    tu = create_team_user(team: t, user: u).extend(Montage::ProjectUser)
    assert_kind_of Hash, tu.as_current_user_info
  end
end 
