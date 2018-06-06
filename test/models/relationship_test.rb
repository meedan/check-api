require_relative '../test_helper'

class RelationshipTest < ActiveSupport::TestCase
  def setup
    super
    Relationship.delete_all
  end

  test "should create relationship" do
    assert_difference 'Relationship.count' do
      create_relationship
    end
  end

  test "should have source" do
    pm = create_project_media
    r = create_relationship source_id: pm.id
    assert_equal pm, r.source
  end

  test "should have target" do
    pm = create_project_media
    r = create_relationship target_id: pm.id
    assert_equal pm, r.target
  end

  test "should not save if source is missing" do
    assert_raises ActiveRecord::StatementInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship source_id: nil
      end
    end
  end

  test "should not save if target is missing" do
    assert_raises ActiveRecord::StatementInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship target_id: nil
      end
    end
  end

  test "should destroy relationships when project media is destroyed" do
    pm = create_project_media
    create_relationship source_id: pm.id
    create_relationship target_id: pm.id
    assert_difference 'Relationship.count', -2 do
      pm.destroy
    end
  end

  test "should validate relationship type" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship relationship_type: { foo: 'foo', bar: 'bar' }
        create_relationship relationship_type: { source: 1, target: 2 }
        create_relationship relationship_type: 'invalid'
        create_relationship relationship_type: ['invalid']
        create_relationship relationship_type: nil
      end
    end
  end

  test "should not have duplicate relationships" do
    s = create_project_media
    t = create_project_media
    name = { source: 'duplicates', target: 'duplicate_of' }
    create_relationship source_id: s.id, target_id: t.id, relationship_type: name
    assert_raises ActiveRecord::StatementInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship source_id: s.id, target_id: t.id, relationship_type: name
      end
    end
  end

  test "should start with targets count zero" do
    pm = create_project_media
    assert_equal 0, pm.targets_count
  end

  test "should increment and decrement targets count when relationship is created or destroyed" do
    pm = create_project_media
    assert_equal 0, pm.targets_count
    create_relationship source_id: pm.id
    assert_equal 1, pm.reload.targets_count
    r = create_relationship source_id: pm.id
    assert_equal 2, pm.reload.targets_count
    r.destroy
    assert_equal 1, pm.reload.targets_count
  end
end
