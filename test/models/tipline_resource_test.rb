require_relative '../test_helper'

class TiplineResourceTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "should create bot resource" do
    assert_difference 'TiplineResource.count' do
      create_tipline_resource
    end
  end

  test "should not create bot resource with empty uuid" do
    assert_no_difference 'TiplineResource.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tipline_resource uuid: ''
      end
    end
  end

  test "should not create bot resource with empty title" do
    assert_no_difference 'TiplineResource.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tipline_resource title: nil
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_tipline_resource title: ''
      end
    end
  end

  test "should belong to team" do
    t = create_team
    br1 = create_tipline_resource team: t
    br2 = create_tipline_resource team: t
    create_tipline_resource
    assert_equal t, br1.team
    assert_equal t, br2.team
    assert_equal [br1, br2].sort, t.tipline_resources.sort
  end

  test "should define a content name" do
    assert_equal 'resource', TiplineResource.content_name
  end
end
