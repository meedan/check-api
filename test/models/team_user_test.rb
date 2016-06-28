require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class TeamUserTest < ActiveSupport::TestCase
  test "should create team user" do
    assert_difference 'TeamUser.count' do
      create_team_user
    end
  end
end
