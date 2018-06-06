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

  test "should return siblings" do
    p = create_project_media
    r = create_relationship source_id: p.id
    s1 = create_project_media
    s2 = create_project_media
    s3 = create_project_media
    create_relationship source_id: p.id, relationship_type: { source: 'foo', target: 'bar' }
    create_relationship target_id: s1.id
    create_relationship source_id: p.id, target_id: s1.id
    create_relationship source_id: p.id, target_id: s2.id
    create_relationship source_id: p.id, target_id: s3.id
    assert_equal [s1, s2, s3].sort, r.siblings.sort
  end

  test "should return targets grouped by type" do
    s = create_project_media
    t1 = create_project_media
    t2 = create_project_media
    t3 = create_project_media
    t4 = create_project_media
    t5 = create_project_media
    t6 = create_project_media
    create_relationship
    create_relationship source_id: s.id, relationship_type: { source: 'duplicates', target: 'duplicate_of' }, target_id: t1.id
    create_relationship source_id: s.id, relationship_type: { source: 'duplicates', target: 'duplicate_of' }, target_id: t2.id
    create_relationship source_id: s.id, relationship_type: { source: 'parent', target: 'child' }, target_id: t3.id
    create_relationship source_id: s.id, relationship_type: { source: 'parent', target: 'child' }, target_id: t4.id
    create_relationship source_id: s.id, relationship_type: { source: 'depends_on', target: 'blocks' }, target_id: t5.id
    create_relationship source_id: s.id, relationship_type: { source: 'depends_on', target: 'blocks' }, target_id: t6.id
    targets = nil
    # Avoid N + 1 problem
    assert_queries 2 do
      targets = Relationship.targets_grouped_by_type(s).sort_by{ |x| x['type'] }
    end
    assert_equal 3, targets.size
    assert_equal({ source: 'depends_on', target: 'blocks' }.to_json, targets[0]['type'])
    assert_equal({ source: 'duplicates', target: 'duplicate_of' }.to_json, targets[1]['type'])
    assert_equal({ source: 'parent', target: 'child' }.to_json, targets[2]['type'])
    assert_equal [t5, t6].sort, targets[0]['targets'].sort
    assert_equal [t1, t2].sort, targets[1]['targets'].sort
    assert_equal [t3, t4].sort, targets[2]['targets'].sort
  end
end
