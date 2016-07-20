require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class TeamUserTest < ActiveSupport::TestCase
  test "should create team user" do
    assert_difference 'TeamUser.count' do
      create_team_user
    end
  end

  test "should get user from callback" do
    u = create_user name: 'test'
    tu = create_team_user
    assert_equal u.id, tu.user_id_callback('test')
  end

  test "should get team from callback" do
    tu = create_team_user
    assert_equal 2, tu.team_id_callback(1, [1, 2, 3])
  end
end
