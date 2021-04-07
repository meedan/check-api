require_relative '../test_helper'

class RelationshipTest < ActiveSupport::TestCase
  def setup
    super
    Sidekiq::Testing.inline!
    @team = create_team
    @project = create_project team: @team
  end

  test "should create relationship" do
    assert_difference 'Relationship.count' do
      create_relationship
    end
  end

  test "should have source" do
    pm = create_project_media(project: @project)
    pm2 = create_project_media(project: @project)
    r = create_relationship source_id: pm.id, target_id: pm2.id
    assert_equal pm, r.source
  end

  test "should have target" do
    pm = create_project_media project: @project
    r = create_relationship target_id: pm.id, source_id: create_project_media(project: @project).id
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
    pm = create_project_media project: @project
    pm2 = create_project_media project: @project
    pm3 = create_project_media project: @project
    create_relationship source_id: pm.id, target_id: pm2.id
    create_relationship target_id: pm.id, source_id: pm3.id
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
    s = create_project_media project: @project
    s2 = create_project_media project: @project
    t = create_project_media project: @project
    t2 = create_project_media project: @project
    name = { source: 'duplicates', target: 'duplicate_of' }
    create_relationship source_id: s.id, target_id: t.id, relationship_type: name
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship source_id: s.id, target_id: t.id, relationship_type: name
      end
    end
    assert_nothing_raised do
      create_relationship source_id: s.id, target_id: t2.id, relationship_type: name
    end
    assert_nothing_raised do
      create_relationship source_id: s2.id, target_id: t.id, relationship_type: name
    end
    assert_nothing_raised do
      create_relationship source_id: s.id, target_id: t.id
    end
  end

  test "should start with targets count zero" do
    pm = create_project_media project: @project
    assert_equal 0, pm.targets_count
  end

  test "should increment and decrement counters when relationship is created or destroyed" do
    s = create_project_media project: @project
    t = create_project_media project: @project
    assert_equal 0, s.targets_count
    assert_equal 0, s.sources_count
    assert_equal 0, t.targets_count
    assert_equal 0, t.sources_count
    r = create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.confirmed_type
    assert_equal 1, s.reload.targets_count
    assert_equal 0, s.reload.sources_count
    assert_equal 1, t.reload.sources_count
    assert_equal 0, t.reload.targets_count
    r.destroy
    assert_equal 0, s.reload.targets_count
    assert_equal 0, s.reload.sources_count
    assert_equal 0, t.reload.sources_count
    assert_equal 0, t.reload.targets_count
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

  test "should not create related report if source report does not exist" do
    pm = create_project_media project: @project
    id = pm.id
    pm.delete
    assert_no_difference 'ProjectMedia.count' do
      assert_no_difference 'Relationship.count' do
        assert_raises RuntimeError do
          create_project_media related_to_id: id, project: @project
        end
      end
    end
  end

  test "should archive or restore medias when source is archived or restored" do
    s = create_project_media project: @project
    t1 = create_project_media project: @project
    t2 = create_project_media project: @project
    create_relationship source_id: s.id, target_id: t1.id
    create_relationship source_id: s.id, target_id: t2.id
    assert_equal 0, t1.reload.archived
    assert_equal 0, t2.reload.archived
    s.archived = 1
    s.save!
    assert_equal 1, t1.reload.archived
    assert_equal 1, t2.reload.archived
    s.archived = 0
    s.save!
    assert_equal 0, t1.reload.archived
    assert_equal 0, t2.reload.archived
  end

  test "should delete medias when source is deleted" do
    s = create_project_media project: @project
    t1 = create_project_media project: @project
    t2 = create_project_media project: @project
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
  
  test "should have a suggested type" do
    assert_not_nil Relationship.suggested_type
  end

  test "should have a confirmed type" do
    assert_not_nil Relationship.confirmed_type
  end

  test "should not be default" do
    s = create_project_media project: @project
    t1 = create_project_media project: @project
    r = create_relationship source_id: s.id, target_id: t1.id, relationship_type: Relationship.confirmed_type
    assert_not r.is_default?
  end

  test "should not be sugggested" do
    s = create_project_media project: @project
    t1 = create_project_media project: @project
    r = create_relationship source_id: s.id, target_id: t1.id
    assert_not r.is_suggested?
  end

  test "should not be confirmed" do
    s = create_project_media project: @project
    t1 = create_project_media project: @project
    r = create_relationship source_id: s.id, target_id: t1.id
    assert_not r.is_confirmed?
  end

  test "should have versions" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    r = create_relationship relationship_type: Relationship.confirmed_type
    assert_empty r.versions
    so = create_project_media project: p
    n = so.cached_annotations_count
    ta = create_project_media project: p
    
    with_current_user_and_team(u, t) do
      r = create_relationship source_id: so.id, target_id: ta.id, relationship_type: Relationship.confirmed_type
    end
    assert_not_empty r.versions
    v = r.versions.last
    assert_equal so.id, v.associated_id
    assert_equal 'ProjectMedia', v.associated_type
    so = ProjectMedia.find(so.id)
    assert so.get_versions_log.map(&:event_type).include?('create_relationship')

    with_current_user_and_team(u, t) do
      ta.destroy
    end
    
    v2 = Version.where(item_type: 'Relationship', item_id: r.id.to_s, event_type: 'destroy_relationship').last
    assert_not_equal v, v2
    assert_equal so.id, v2.associated_id
    assert_equal 'ProjectMedia', v2.associated_type
    so = ProjectMedia.find(so.id)
    assert so.get_versions_log.map(&:event_type).include?('destroy_relationship')
    assert_not_nil v2.meta
  end

  test "should not crash if can't delete from ElasticSearch" do
    r = create_relationship
    assert_nothing_raised do
      r.destroy_elasticsearch_doc({})
    end
  end

  test "should propagate change if source and target are swapped" do
    u = create_user is_admin: true
    t = create_team
    with_current_user_and_team(u, t) do
      s = create_project_media project: @project
      t1 = create_project_media project: @project
      t2 = create_project_media project: @project
      t3 = create_project_media project: @project
      r1 = create_relationship source_id: s.id, target_id: t1.id
      r2 = create_relationship source_id: s.id, target_id: t2.id
      r3 = create_relationship source_id: s.id, target_id: t3.id
      r1.source_id = t1.id
      r1.target_id = s.id
      r1.save!
      assert_equal t1, r2.reload.source
      assert_equal t2, r2.reload.target
      assert_equal t1, r3.reload.source
      assert_equal t3, r3.reload.target
    end
  end

  test "should not relate items from different teams" do
    t1 = create_team
    t2 = create_team
    pm1 = create_project_media team_id: t1.id
    pm2 = create_project_media team_id: t2.id
    assert_raises ActiveRecord::RecordInvalid do
      create_relationship source_id: pm1.id, target_id: pm2.id
    end
    p1 = create_project team: t1
    p2 = create_project team: t2
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    assert_raises ActiveRecord::RecordInvalid do
      create_relationship source_id: pm1.id, target_id: pm2.id
    end
  end

  test "should set source type and target type independently" do
    r = Relationship.new
    r.relationship_source_type = 'confirmed_sibling'
    r.relationship_target_type = 'confirmed_sibling'
    assert r.is_confirmed?
  end

  test "should detach to specific list" do
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    pm_s = create_project_media team: t
    pm_t = create_project_media project: p
    r = create_relationship source_id: pm_s.id, target_id: pm_t.id, relationship_type: Relationship.confirmed_type
    assert_equal p.id, pm_t.project_id
    r.add_to_project_id = p2.id
    r.destroy
    assert_equal p2.id, pm_t.reload.project_id.sort

  end

  test "should re-point targets to new source when adding as a target an item that already has targets" do
    t = create_team
    i1 = create_project_media(team: t).id
    i11 = create_project_media(team: t).id
    i111 = create_project_media(team: t).id
    create_relationship source_id: i11, target_id: i111, relationship_type: Relationship.confirmed_type
    create_relationship source_id: i1, target_id: i11, relationship_type: Relationship.confirmed_type
    assert_not_nil Relationship.where(source_id: i1, target_id: i11).last
    assert_not_nil Relationship.where(source_id: i1, target_id: i111).last
    assert_nil Relationship.where(source_id: i11, target_id: i111).last
  end

  test "should not attempt to update source count if source does not exist" do
    r = create_relationship relationship_type: Relationship.confirmed_type
    r.source.delete
    assert_nothing_raised do
      r.reload.send :update_counters
    end
  end

  test "should cache the name of who created a similar item" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user is_admin: true
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    r = nil
    with_current_user_and_team(u, t) do
      r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type, user: nil
    end
    assert_queries(0, '=') { assert_equal u.name, pm2.added_as_similar_by_name }
    Rails.cache.delete("check_cached_field:ProjectMedia:#{pm2.id}:added_as_similar_by_name")
    assert_queries(0, '>') { assert_equal u.name, pm2.added_as_similar_by_name }
    r.destroy!
    assert_queries(0, '=') { assert_nil pm2.added_as_similar_by_name }
  end

  test "should cache the name of who confirmed a similar item and store confirmation information" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user is_admin: true
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type, user: create_user(is_admin: true)
    assert_nil r.reload.confirmed_at
    assert_nil r.reload.confirmed_by
    with_current_user_and_team(u, t) do
      r.relationship_type = Relationship.confirmed_type
      r.save!
    end
    assert_queries(0, '=') { assert_equal u.name, pm2.confirmed_as_similar_by_name }
    assert_not_nil r.reload.confirmed_at
    assert_equal u.id, r.reload.confirmed_by
    Rails.cache.delete("check_cached_field:ProjectMedia:#{pm2.id}:confirmed_as_similar_by_name")
    assert_queries(0, '>') { assert_equal u.name, pm2.confirmed_as_similar_by_name }
    r.destroy!
    assert_queries(0, '=') { assert_nil pm2.confirmed_as_similar_by_name }
  end
end
