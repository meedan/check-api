require_relative '../test_helper'

class RelationshipTest < ActiveSupport::TestCase
  def setup
    super
    Relationship.delete_all
    Sidekiq::Testing.inline!
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

  test "should increment and decrement counters when relationship is created or destroyed" do
    s = create_project_media
    t = create_project_media
    assert_equal 0, s.targets_count
    assert_equal 0, s.sources_count
    assert_equal 0, t.targets_count
    assert_equal 0, t.sources_count
    create_relationship source_id: s.id, target_id: t.id, relationship_type: { source: 'foo', target: 'bar' }
    assert_equal 1, s.reload.targets_count
    assert_equal 0, s.reload.sources_count
    assert_equal 1, t.reload.sources_count
    assert_equal 0, t.reload.targets_count
    r = create_relationship source_id: s.id, target_id: t.id
    assert_equal 2, s.reload.targets_count
    assert_equal 0, s.reload.sources_count
    assert_equal 2, t.reload.sources_count
    assert_equal 0, t.reload.targets_count
    r.destroy
    assert_equal 1, s.reload.targets_count
    assert_equal 0, s.reload.sources_count
    assert_equal 1, t.reload.sources_count
    assert_equal 0, t.reload.targets_count
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

  test "should create related report" do
    p = create_project
    pm = create_project_media project: p
    assert_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        assert_nothing_raised do
          create_project_media related_to_id: pm, project: p
        end
      end
    end
  end

  test "should not create related report if project is not the same" do
    pm = create_project_media
    assert_no_difference 'ProjectMedia.count' do
      assert_no_difference 'Relationship.count' do
        assert_raises RuntimeError do
          create_project_media related_to_id: pm
        end
      end
    end
  end

  test "should not create related report if source report does not exist" do
    pm = create_project_media
    id = pm.id
    pm.delete
    assert_no_difference 'ProjectMedia.count' do
      assert_no_difference 'Relationship.count' do
        assert_raises RuntimeError do
          create_project_media related_to_id: id
        end
      end
    end
  end

  test "should not update relationship" do
    r = create_relationship
    r.relationship_type = { source: 'foo', target: 'bar' }
    assert_raises ActiveRecord::ReadOnlyRecord do
      r.save!
    end
  end

  test "should archive or restore medias when source is archived or restored" do
    s = create_project_media
    t1 = create_project_media
    t2 = create_project_media
    create_relationship source_id: s.id, target_id: t1.id
    create_relationship source_id: s.id, target_id: t2.id
    assert !t1.reload.archived
    assert !t2.reload.archived
    s.archived = true
    s.save!
    assert t1.reload.archived
    assert t2.reload.archived
    s.archived = false
    s.save!
    assert !t1.reload.archived
    assert !t2.reload.archived
  end

  test "should delete medias when source is deleted" do
    s = create_project_media
    t1 = create_project_media
    t2 = create_project_media
    create_relationship source_id: s.id, target_id: t1.id
    create_relationship source_id: s.id, target_id: t2.id
    assert_not_nil ProjectMedia.where(id: t1.id).last
    assert_not_nil ProjectMedia.where(id: t2.id).last
    s.destroy
    assert_nil ProjectMedia.where(id: t1.id).last
    assert_nil ProjectMedia.where(id: t2.id).last
  end

  test "should have a default type" do
    assert_not_nil Relationship.default_type
  end

  test "should get target id" do
    assert_kind_of String, Relationship.target_id(create_project_media)
  end

  test "should get source id" do
    assert_kind_of String, Relationship.source_id(create_project_media)
  end

  test "should have versions" do
    u = create_user is_admin: true
    t = create_team
    r = create_relationship
    assert_empty r.versions
    so = create_project_media
    n = so.cached_annotations_count
    ta = create_project_media
    
    with_current_user_and_team(u, t) do
      r = create_relationship source_id: so.id, target_id: ta.id
    end
    
    assert_not_empty r.versions
    v = r.versions.last
    assert_equal so.id, v.associated_id
    assert_equal 'ProjectMedia', v.associated_type
    assert_equal n + 1, so.reload.cached_annotations_count
    assert so.get_versions_log.map(&:event_type).include?('create_relationship')

    with_current_user_and_team(u, t) do
      ta.destroy
    end
    
    v2 = PaperTrail::Version.where(event_type: 'destroy_relationship').last
    assert_not_equal v, v2
    assert_equal so.id, v2.associated_id
    assert_equal 'ProjectMedia', v2.associated_type
    assert_equal n + 2, so.reload.cached_annotations_count
    assert so.get_versions_log.map(&:event_type).include?('destroy_relationship')
    assert_not_nil v2.meta
  end

  test "should not crash if can't delete from ElasticSearch" do
    r = create_relationship
    assert_nothing_raised do
      r.destroy_elasticsearch_doc({})
    end
  end
end
