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
    r = create_relationship relationship_type: Relationship.confirmed_type, source_id: pm1.id, target_id: pm2.id
    assert_equal p1, pm1.reload.project
    assert_equal p1, pm2.reload.project
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
    pm_s = create_project_media team: t, disable_es_callbacks: false
    pm_t = create_project_media team: t, disable_es_callbacks: false
    pm_t2 = create_project_media team: t, disable_es_callbacks: false
    pm_t3 = create_project_media team: t, disable_es_callbacks: false
    r = create_relationship source_id: pm_s.id, target_id: pm_t.id, relationship_type: Relationship.suggested_type
    sleep 2
    es_t = $repository.find(get_es_id(pm_t))
    assert_equal pm_t.id, es_t['parent_id']
    assert_equal pm_t.reload.sources_count, es_t['sources_count']
    assert_equal 0, pm_t.reload.sources_count
    # Confirm item
    r.relationship_type = Relationship.confirmed_type
    r.save!
    r2 = create_relationship source_id: pm_s.id, target_id: pm_t2.id, relationship_type: Relationship.confirmed_type
    r3 = create_relationship source_id: pm_s.id, target_id: pm_t3.id, relationship_type: Relationship.suggested_type
    sleep 1
    es_s = $repository.find(get_es_id(pm_s))
    assert_equal pm_s.id, es_s['parent_id']
    assert_equal pm_s.reload.sources_count, es_s['sources_count']
    assert_equal 0, pm_s.reload.sources_count
    [pm_t, pm_t2].each do |pm|
      es = $repository.find(get_es_id(pm))
      assert_equal pm_s.id, es['parent_id']
      assert_equal pm.reload.sources_count, es['sources_count']
      assert_equal 1, pm.reload.sources_count
    end
    # Verify parent_id after pin another item
    r2.source_id = pm_t2.id
    r2.target_id = pm_s.id
    r2.disable_es_callbacks = false
    r2.save!
    sleep 1
    es_t2 = $repository.find(get_es_id(pm_t2))
    assert_equal pm_t2.id, es_t2['parent_id']
    assert_equal pm_t2.reload.sources_count, es_t2['sources_count']
    assert_equal 0, pm_t2.reload.sources_count
    [pm_s, pm_t].each do |pm|
      es = $repository.find(get_es_id(pm))
      assert_equal pm_t2.id, es['parent_id']
      assert_equal pm.reload.sources_count, es['sources_count']
      assert_equal 1, pm.reload.sources_count
    end
    # Verify destory
    r.destroy!
    es_t = $repository.find(get_es_id(pm_t))
    assert_equal pm_t.id, es_t['parent_id']
  end

  test "should remove suggested relation when same items added as similar" do
    team = create_team
    b = create_bot name: 'Alegre', login: 'alegre'
    s = create_project_media team: team
    t = create_project_media team: team
    r = create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.suggested_type, user: b
    r2 = create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.confirmed_type, user: b
    assert_nil Relationship.where(id: r.id).last
    assert_not_nil Relationship.where(id: r2.id).last
    assert_raises ActiveRecord::RecordInvalid do
      create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.suggested_type, user: b
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
        # Try to create an item with title that trigger a version metadata error(CV2-2910)
        pm_s = create_project_media team: t, quote: "Rahul Gandhi's interaction with Indian?param:test&Journalists Association in London"
        pm_t1 = create_project_media team: t
        pm_t2 = create_project_media team: t
        pm_t3 = create_project_media team: t
        r1 = create_relationship source_id: pm_s.id, target_id: pm_t1.id, relationship_type: Relationship.suggested_type
        r2 = create_relationship source_id: pm_s.id, target_id: pm_t2.id, relationship_type: Relationship.suggested_type
        r3 = create_relationship source_id: pm_s.id, target_id: pm_t3.id, relationship_type: Relationship.suggested_type
        # Verify unmatched
        assert_equal 0, pm_s.reload.unmatched
        assert_equal 0, pm_t1.reload.unmatched
        assert_equal 0, pm_t2.reload.unmatched
        assert_equal 0, pm_t3.reload.unmatched
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
        # Verify unmatched
        assert_equal 0, pm_s.reload.unmatched
        assert_equal 0, pm_t1.reload.unmatched
        assert_equal 0, pm_t2.reload.unmatched
        assert_equal 0, pm_t3.reload.unmatched
      end
    end
  end

  test "should bulk-reject similar items" do
    RequestStore.store[:skip_cached_field_update] = false
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
        updates = { source_id: pm_s.id }
        assert_difference 'Version.count', 2 do
          Relationship.bulk_destroy(ids, updates, t)
        end
        assert_equal 1, pm_t1.reload.unmatched
        assert_equal 1, pm_t2.reload.unmatched
        assert_equal 0, pm_t3.reload.unmatched
        assert_equal 0, pm_s.reload.unmatched
        # Verify cached fields
        assert_not pm_t1.is_suggested
        assert_not pm_t1.is_suggested(true)
        r3.destroy!
        assert_equal 1, pm_t3.reload.unmatched
        assert_equal 1, pm_s.reload.unmatched
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

  test "should move explainer to source after pin item or match items" do
    t = create_team
    e = create_explainer team: t
    e_s = create_explainer team: t
    e_t = create_explainer team: t
    source = create_project_media team: t
    target = create_project_media team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_versioning do
      with_current_user_and_team(u, t) do
        source.explainers << e
        source.explainers << e_s
        target.explainers << e
        target.explainers << e_t
      end
    end
    assert_equal 2, source.explainer_items.count
    assert_equal 2, target.explainer_items.count
    sv_count = Version.from_partition(t.id).where(event_type: 'create_explaineritem', associated_id: source.id).count
    tv_count = Version.from_partition(t.id).where(event_type: 'create_explaineritem', associated_id: target.id).count
    assert_equal 2, sv_count
    assert_equal 2, tv_count
    r = create_relationship source_id: source.id, target_id: target.id, relationship_type: Relationship.confirmed_type
    assert_equal 3, source.explainer_items.count
    assert_equal 0, target.explainer_items.count
    sv_count = Version.from_partition(t.id).where(event_type: 'create_explaineritem', associated_id: source.id).count
    tv_count = Version.from_partition(t.id).where(event_type: 'create_explaineritem', associated_id: target.id).count
    assert_equal 4, sv_count
    assert_equal 0, tv_count
    # Pin target item
    r.source_id = target.id
    r.target_id = source.id
    r.save!
    assert_equal 0, source.explainer_items.count
    assert_equal 3, target.explainer_items.count
    sv_count = Version.from_partition(t.id).where(event_type: 'create_explaineritem', associated_id: source.id).count
    tv_count = Version.from_partition(t.id).where(event_type: 'create_explaineritem', associated_id: target.id).count
    assert_equal 0, sv_count
    assert_equal 4, tv_count
    # should not move for similar item
    pm2_s = create_project_media team: t
    pm2 = create_project_media team: t
    e2 = create_explainer team: t
    pm2.explainers << e
    r2 = create_relationship source_id: pm2_s.id, target_id: pm2.id, relationship_type: Relationship.suggested_type
    assert_equal 1, pm2.explainer_items.count
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
    assert_difference 'Relationship.count' do
      create_relationship source_id: pm1.id, target_id: pm2.id
    end
    assert_no_difference 'Relationship.count' do
      create_relationship source_id: pm2.id, target_id: pm1.id
    end
    pm3 = create_project_media
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_relationship source_id: pm3.id, target_id: pm3.id
      end
    end
  end

  test "should create relationship unless exists" do
    Sidekiq::Testing.fake!
    t = create_team
    u = create_user
    source = create_project_media team: t
    target = create_project_media team: t
    r = nil
    assert_difference 'Relationship.count' do
      r = Relationship.create_unless_exists(source.id, target.id, Relationship.confirmed_type, { user_id: u.id })
    end
    assert_equal u.id, r.user_id
    r2 = nil
    assert_no_difference 'Relationship.count' do
      r2 = Relationship.create_unless_exists(source.id, target.id, Relationship.confirmed_type)
    end
    assert_equal r, r2
    # Should update type if the new one is confirmed
    target = create_project_media team: t
    r = create_relationship source_id: source.id, target_id: target.id, relationship_type: Relationship.suggested_type, user: create_bot_user
    r2 = nil
    assert_no_difference 'Relationship.count' do
      r2 = Relationship.create_unless_exists(source.id, target.id, Relationship.confirmed_type)
    end
    assert_nil Relationship.where(id: r.id).last
    assert_equal Relationship.confirmed_type, r2.relationship_type
    Relationship.any_instance.stubs(:save!).raises(ActiveRecord::RecordNotUnique)
    target = create_project_media team: t
    r = nil
    assert_no_difference 'Relationship.count' do
      r = Relationship.create_unless_exists(source.id, target.id, Relationship.confirmed_type)
    end
    assert_nil r
    Relationship.any_instance.unstub(:save)
  end

  test "should revert rejecting suggestion when creation fails" do
    Sidekiq::Testing.fake!
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    suggestion = create_relationship source: pm1, target: pm2, relationship_type: Relationship.suggested_type, user: create_bot_user

    p = create_project
    p.archived = CheckArchivedFlags::FlagCodes::TRASHED
    p.save!
    pm1.update_column(:project_id, p.id) # Just to force an error

    begin
      Relationship.create!(source: pm1, target: pm2, relationship_type: Relationship.confirmed_type)
    rescue
      # Validation error
    end
    assert_equal 1, Relationship.where(source_id: pm1.id, target: pm2.id).count
    assert_equal suggestion, Relationship.where(source_id: pm1.id, target: pm2.id).last
  end

  test "should revert rejecting suggestion when creation fails (using create_unless_exists)" do
    Sidekiq::Testing.fake!
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    suggestion = create_relationship source: pm1, target: pm2, relationship_type: Relationship.suggested_type, user: create_bot_user

    p = create_project
    p.archived = CheckArchivedFlags::FlagCodes::TRASHED
    p.save!
    pm1.update_column(:project_id, p.id) # Just to force an error

    begin
      Relationship.create_unless_exists(pm1.id, pm2.id, Relationship.confirmed_type)
    rescue
      # Validation error
    end
    assert_equal 1, Relationship.where(source_id: pm1.id, target: pm2.id).count
    assert_equal suggestion, Relationship.where(source_id: pm1.id, target: pm2.id).last
  end

  test "should not be related to itself" do
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    r = create_relationship source: pm1, target: pm2
    begin
      r.update_column :target_id, pm1.id
      flunk 'Expected save to fail, but it succeeded'
    rescue ActiveRecord::StatementInvalid => e
      assert_match /violates check constraint "source_target_must_be_different"/, e.message
    end
  end

  test "should move similar items when export item" do
    Sidekiq::Testing.fake!
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    pm1a = create_project_media team: t
    pm1b = create_project_media team: t
    pm2a = create_project_media team: t
    pm2b = create_project_media team: t
    # Add pm1a & pm1b as a similar items to pm1
    create_relationship source_id: pm1.id, target_id: pm1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: pm1.id, target_id: pm1b.id, relationship_type: Relationship.suggested_type
    # Add pm2a & pm2b as a similar items to pm2
    create_relationship source_id: pm2.id, target_id: pm2a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: pm2.id, target_id: pm2b.id, relationship_type: Relationship.suggested_type
    # Export pm1 to pm2
    create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    assert_equal 4, Relationship.where(source_id: pm1.id, relationship_type: Relationship.suggested_type).count
    assert_equal 0, Relationship.where(source_id: pm2.id, relationship_type: Relationship.suggested_type).count
  end

  test "should update media origin when bulk-accepting suggestion" do
    Sidekiq::Testing.inline!
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user is_admin: true

    # Create suggestion
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type
    assert_equal CheckMediaClusterOrigins::OriginCodes::AUTO_MATCHED, pm2.media_cluster_origin

    # Accept suggestion
    with_current_user_and_team u, t do
      Relationship.bulk_update([r.id], { source_id: pm1.id, action: 'accept' }, t)
    end
    assert_equal CheckMediaClusterOrigins::OriginCodes::USER_MATCHED, pm2.media_cluster_origin
  end
end
