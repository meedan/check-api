require_relative '../test_helper'

class BotResourceTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "should create bot resource" do
    assert_difference 'BotResource.count' do
      create_bot_resource
    end
  end

  test "should not create bot resource with empty uuid" do
    assert_no_difference 'BotResource.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_bot_resource uuid: nil
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_bot_resource uuid: ''
      end
    end
  end

  test "should not create bot resource with empty title" do
    assert_no_difference 'BotResource.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_bot_resource title: nil
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_bot_resource title: ''
      end
    end
  end

  test "should belong to team" do
    t = create_team
    br1 = create_bot_resource team: t
    br2 = create_bot_resource team: t
    create_bot_resource
    assert_equal t, br1.team
    assert_equal t, br2.team
    assert_equal [br1, br2].sort, t.bot_resources.sort
  end
end
