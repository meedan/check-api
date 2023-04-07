require_relative '../test_helper'

class RelationshipTest < ActiveSupport::TestCase
  def setup
    super
    Sidekiq::Testing.inline!
    @team = create_team
    @project = create_project team: @team
  end

  test "should move secondary item to same folder as main" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media team: t, project: p1
    pm2 = create_project_media team: t, project: p2
    assert_equal p1, pm1.reload.project
    assert_equal p2, pm2.reload.project
    assert_equal 1, p1.reload.medias_count
    assert_equal 1, p2.reload.medias_count
    r = create_relationship relationship_type: Relationship.confirmed_type, source_id: pm1.id, target_id: pm2.id
    assert_equal p1, pm1.reload.project
    assert_equal p1, pm2.reload.project
    assert_equal 1, p1.reload.medias_count
    assert_equal 0, p2.reload.medias_count
  end

  test "should create relationship between items with same media" do
    t = create_team
    m = create_valid_media
    pm1 = create_project_media media: m, team: t
    pm2 = ProjectMedia.new
    pm2.media = m
    pm2.team = t
    pm2.save(validate: false)
    create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
  end

  test "should update sources_count and parent_id for confirmed item" do
    setup_elasticsearch
    t = create_team
    pm_s = create_project_media team: t
    pm_t = create_project_media team: t
    r = create_relationship source_id: pm_s.id, target_id: pm_t.id, relationship_type: Relationship.suggested_type
    sleep 2
    es_t = $repository.find(get_es_id(pm_t))
    assert_equal pm_t.id, es_t['parent_id']
    assert_equal pm_t.reload.sources_count, es_t['sources_count']
    assert_equal 0, pm_t.reload.sources_count
    # Confirm item
    r.relationship_type = Relationship.confirmed_type
    r.save!
    sleep 2
    es_t = $repository.find(get_es_id(pm_t))
    assert_equal r.source_id, es_t['parent_id']
    assert_equal pm_t.reload.sources_count, es_t['sources_count']
    assert_equal 1, pm_t.reload.sources_count
    r.destroy!
    es_t = $repository.find(get_es_id(pm_t))
    assert_equal pm_t.id, es_t['parent_id']
  end

  test "should set cluster" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    s = create_project_media team: t
    t = create_project_media team: t
    s_c = create_cluster project_media: s
    s_c.project_medias << s
    t_c = create_cluster project_media: t
    t_c.project_medias << t
    User.stubs(:current).returns(u)
    create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.confirmed_type
    assert_nil Cluster.where(id: t_c.id).last
    assert_equal [s.id, t.id].sort, s_c.reload.project_media_ids.sort
    User.unstub(:current)
  end

  test "should remove suggested relation when same items added as similar" do
    team = create_team
    s = create_project_media team: team
    t = create_project_media team: team
    r = create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.suggested_type
    r2 = create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.confirmed_type
    assert_nil Relationship.where(id: r.id).last
    assert_not_nil Relationship.where(id: r2.id).last
    assert_raises ActiveRecord::RecordInvalid do
      create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.suggested_type
    end
  end

  test "should verify versions and ES for bulk-update" do
    with_versioning do
      setup_elasticsearch
      RequestStore.store[:skip_cached_field_update] = false
      t = create_team
      u = create_user
      create_team_user team: t, user: u, role: 'admin'
      with_current_user_and_team(u, t) do
        pm_s = create_project_media team: t
        pm_t1 = create_project_media team: t
        pm_t2 = create_project_media team: t
        pm_t3 = create_project_media team: t
        r1 = create_relationship source_id: pm_s.id, target_id: pm_t1.id, relationship_type: Relationship.suggested_type
        r2 = create_relationship source_id: pm_s.id, target_id: pm_t2.id, relationship_type: Relationship.suggested_type
        r3 = create_relationship source_id: pm_s.id, target_id: pm_t3.id, relationship_type: Relationship.suggested_type
        # Verify cached fields
        sleep 2
        es_s = $repository.find(get_es_id(pm_s))
        assert_equal 3, pm_s.suggestions_count
        assert_equal pm_s.suggestions_count, es_s['suggestions_count']
        relations = [r1, r2]
        ids = relations.map(&:id)
        updates = { action: "accept", source_id: pm_s.id }
        assert_difference 'Version.count', 2 do
          Relationship.bulk_update(ids, updates, t)
        end
        assert_equal Relationship.suggested_type, r3.reload.relationship_type
        assert_equal Relationship.confirmed_type, r1.reload.relationship_type
        assert_equal Relationship.confirmed_type, r2.reload.relationship_type
        # Verify confirmed_by
        assert_equal [u.id], Relationship.where(id: ids).map(&:confirmed_by).uniq
        # Verify cached fields
        assert_equal 1, pm_s.suggestions_count
        assert_equal 1, pm_s.suggestions_count(true)
        sleep 2
        # Verify ES
        es_s = $repository.find(get_es_id(pm_s))
        es_t = $repository.find(get_es_id(pm_t1))
        assert_equal r1.source_id, es_t['parent_id']
        assert_equal pm_t1.reload.sources_count, es_t['sources_count']
        assert_equal 1, pm_t1.reload.sources_count
        assert_equal pm_s.suggestions_count, es_s['suggestions_count']
      end
    end
  end

  test "should bulk-reject similar items" do
    with_versioning do
      setup_elasticsearch
      t = create_team
      u = create_user
      p = create_project team: t
      p2 = create_project team: t
      create_team_user team: t, user: u, role: 'admin'
      with_current_user_and_team(u, t) do
        pm_s = create_project_media team: t, project: p
        pm_t1 = create_project_media team: t, project: p
        pm_t2 = create_project_media team: t, project: p
        pm_t3 = create_project_media team: t, project: p
        r1 = create_relationship source_id: pm_s.id, target_id: pm_t1.id, relationship_type: Relationship.suggested_type
        r2 = create_relationship source_id: pm_s.id, target_id: pm_t2.id, relationship_type: Relationship.suggested_type
        r3 = create_relationship source_id: pm_s.id, target_id: pm_t3.id, relationship_type: Relationship.suggested_type
        relations = [r1, r2]
        ids = relations.map(&:id)
        updates = { source_id: pm_s.id, add_to_project_id: p2.id }
        assert_difference 'Version.count', 2 do
          Relationship.bulk_destroy(ids, updates, t)
        end
        assert_equal p2.id, pm_t1.reload.project_id
        assert_equal p2.id, pm_t2.reload.project_id
        assert_equal p.id, pm_t3.reload.project_id
      end
    end
  end

  test "should inherit report when pinning new main item" do
    t = create_team
    pm1 = create_project_media team: t
    create_claim_description project_media: pm1
    pm2 = create_project_media team: t
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    publish_report(pm1)
    assert_not_nil pm1.get_dynamic_annotation('report_design')
    assert_nil pm2.get_dynamic_annotation('report_design')

    r = Relationship.find(r.id)
    r.source_id = pm2.id
    r.target_id = pm1.id
    r.save!
    assert_nil pm1.get_dynamic_annotation('report_design')
    assert_not_nil pm2.get_dynamic_annotation('report_design')
  end

  test "should pin item when both have claims" do
    t = create_team
    pm1 = create_project_media team: t
    create_claim_description project_media: pm1
    pm2 = create_project_media team: t
    create_claim_description project_media: pm2
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type

    assert_nothing_raised do
      r = Relationship.find(r.id)
      r.source_id = pm2.id
      r.target_id = pm1.id
      r.save!
    end
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

  test "should avoid circular relationship" do
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    assert_nothing_raised do
      create_relationship source_id: pm1.id, target_id: pm2.id
    end
    assert_raises 'ActiveRecord::RecordNotUnique' do
      create_relationship source_id: pm2.id, target_id: pm1.id
    end
    pm3 = create_project_media
    assert_raises 'ActiveRecord::RecordInvalid' do
      create_relationship source_id: pm3.id, target_id: pm3.id
    end
  end
end
