require 'test_helper'

class TeamTest < ActiveSupport::TestCase

  test "should create team" do
    assert_difference 'Team.count' do
      create_team
    end
  end

  test "should not save team without name" do
    team = Team.new
    assert_not  team.save
  end

end
