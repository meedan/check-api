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
    tr1 = create_tipline_resource team: t
    tr2 = create_tipline_resource team: t
    create_tipline_resource
    assert_equal t, tr1.team
    assert_equal t, tr2.team
    assert_equal [tr1, tr2].sort, t.tipline_resources.sort
  end

  test "should define a content name" do
    assert_equal 'resource', TiplineResource.content_name
  end

  test "should have static content" do
    tr = create_tipline_resource title: 'Foo', content: 'Bar', content_type: 'static'
    assert_equal "*Foo*\n\nBar", tr.format_as_tipline_message
  end

  test "should not set NLU keywords directly" do
    tr = create_tipline_resource
    assert_raises StandardError do
      tr.keywords = ['foo', 'bar']
      tr.save!
    end
  end
end
