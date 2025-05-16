require_relative '../test_helper'

class Relationship2Test < ActiveSupport::TestCase
  def setup
    Sidekiq::Testing.fake!
    @team = create_team
  end

  def teardown
    User.current = Team.current = nil
  end

  test "should create relationship" do
    assert_difference 'Relationship.count' do
      create_relationship
    end
  end

  test "should have source" do
    pm = create_project_media(team: @team)
    pm2 = create_project_media(team: @team)
    r = create_relationship source_id: pm.id, target_id: pm2.id
    assert_equal pm, r.source
  end

  test "should have target" do
    pm = create_project_media team: @team
    r = create_relationship target_id: pm.id, source_id: create_project_media(team: @team).id
    assert_equal pm, r.target
  end

  test "should not have a published target" do
    create_verification_status_stuff
    s = create_project_media team: @team
    t = create_project_media team: @team
    publish_report(t)
    assert_raises ActiveRecord::RecordInvalid do
      create_relationship source_id: s.id, target_id: t.id
    end
  end

  test "should not save if source is missing" do
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_relationship source_id: nil
      end
    end
  end

  test "should not save if target is missing" do
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_relationship target_id: nil
      end
    end
  end

  test "should destroy relationships when project media is destroyed" do
    Sidekiq::Testing.inline!
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    pm3 = create_project_media team: @team
    create_relationship source_id: pm.id, target_id: pm2.id
    create_relationship source_id: pm.id, target_id: pm3.id
    assert_difference 'Relationship.count', -2 do
      pm.destroy
    end
  end

  test "should validate relationship type" do
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_relationship relationship_type: { foo: 'foo', bar: 'bar' }
        create_relationship relationship_type: { source: 1, target: 2 }
        create_relationship relationship_type: 'invalid'
        create_relationship relationship_type: ['invalid']
        create_relationship relationship_type: nil
      end
    end
  end

  test "should not have duplicate relationships" do
    s = create_project_media team: @team
    s2 = create_project_media team: @team
    t = create_project_media team: @team
    t2 = create_project_media team: @team
    name = { source: 'duplicates', target: 'duplicate_of' }
    create_relationship source_id: s.id, target_id: t.id, relationship_type: name
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_relationship source_id: s.id, target_id: t.id, relationship_type: name
      end
    end
  end

  test "should increment and decrement counters when relationship is created or destroyed" do
    RequestStore.store[:skip_cached_field_update] = false
    s = create_project_media team: @team
    t = create_project_media team: @team
    assert_equal 0, s.sources_count
    assert_equal 0, t.sources_count
    r = create_relationship source_id: s.id, target_id: t.id, relationship_type: Relationship.confirmed_type
    assert_equal 0, s.reload.sources_count
    assert_equal 1, t.reload.sources_count
    r.destroy
    assert_equal 0, s.reload.sources_count
    assert_equal 0, t.reload.sources_count
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
    pm = create_project_media team: @team
    id = pm.id
    pm.delete
    assert_no_difference 'ProjectMedia.count' do
      assert_no_difference 'Relationship.count' do
        assert_raises RuntimeError do
          create_project_media related_to_id: id, team: @team
        end
      end
    end
  end

  test "should archive or restore medias when source is archived or restored" do
    Sidekiq::Testing.inline!
    RequestStore.store[:skip_delete_for_ever] = true
    s = create_project_media team: @team
    t1 = create_project_media team: @team
    t2 = create_project_media team: @team
    create_relationship source_id: s.id, target_id: t1.id
    create_relationship source_id: s.id, target_id: t2.id
    assert_equal CheckArchivedFlags::FlagCodes::NONE, t1.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, t2.reload.archived
    s.archived = CheckArchivedFlags::FlagCodes::TRASHED
    s.save!
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, t1.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, t2.reload.archived
    s.archived = CheckArchivedFlags::FlagCodes::NONE
    s.save!
    assert_equal CheckArchivedFlags::FlagCodes::NONE, t1.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, t2.reload.archived
  end

  test "should delete medias when source is deleted" do
    Sidekiq::Testing.inline!
    s = create_project_media team: @team
    t1 = create_project_media team: @team
    t2 = create_project_media team: @team
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
    s = create_project_media team: @team
    t1 = create_project_media team: @team
    r = create_relationship source_id: s.id, target_id: t1.id, relationship_type: Relationship.confirmed_type
    assert_not r.is_default?
  end

  test "should not be sugggested" do
    s = create_project_media team: @team
    t1 = create_project_media team: @team
    r = create_relationship source_id: s.id, target_id: t1.id
    assert_not r.is_suggested?
  end

  test "should not be confirmed" do
    s = create_project_media team: @team
    t1 = create_project_media team: @team
    r = create_relationship source_id: s.id, target_id: t1.id
    assert_not r.is_confirmed?
  end

  test "should have versions" do
    Sidekiq::Testing.inline!
    with_versioning do
      u = create_user is_admin: true
      t = create_team
      p = create_project team: t
      r = create_relationship relationship_type: Relationship.confirmed_type
      assert_empty r.versions
      so = create_project_media project: p
      ta = create_project_media project: p
      
      with_current_user_and_team(u, t) do
        r = create_relationship source_id: so.id, target_id: ta.id, relationship_type: Relationship.confirmed_type
      end
      assert_not_empty r.versions
      v = r.versions.last
      assert_equal ta.id, v.associated_id
      assert_equal 'ProjectMedia', v.associated_type
      ta = ProjectMedia.find(ta.id)
      assert ta.get_versions_log.map(&:event_type).include?('create_relationship')

      with_current_user_and_team(u, t) do
        ta.destroy
      end
      
      v2 = Version.where(item_type: 'Relationship', item_id: r.id.to_s, event_type: 'destroy_relationship').last
      assert_not_equal v, v2
      assert_equal ta.id, v2.associated_id
      assert_equal 'ProjectMedia', v2.associated_type
    end
  end

  test "should not crash if can't delete from ElasticSearch" do
    r = create_relationship
    assert_nothing_raised do
      Relationship.destroy_elasticsearch_doc({})
    end
  end

  test "should propagate change if source and target are swapped" do
    Sidekiq::Testing.inline!
    u = create_user is_admin: true
    t = create_team
    with_current_user_and_team(u, t) do
      s = create_project_media team: @team
      t1 = create_project_media team: @team
      t2 = create_project_media team: @team
      t3 = create_project_media team: @team
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
    # should re-point if same target exists in two relationships
    s1 = create_project_media team: t
    s2 = create_project_media team: t
    t = create_project_media team: t
    create_relationship source_id: s1.id, target_id: t.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: s2.id, target_id: s1.id, relationship_type: Relationship.confirmed_type
    assert_equal 0, Relationship.where(source_id: s1.id).count
    assert_equal 2, Relationship.where(source_id: s2.id).count
    assert_nil Relationship.where(source_id: s1, target_id: t).last
    assert_not_nil Relationship.where(source_id: s2, target_id: t).last
    assert_not_nil Relationship.where(source_id: s2, target_id: s1).last
  end

  test "should clear cache when inverting relationship" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    r = create_relationship relationship_type: Relationship.confirmed_type, source_id: pm1.id, target_id: pm2.id
    assert_equal 2, pm1.reload.linked_items_count
    assert_equal 1, pm2.reload.linked_items_count
    r = Relationship.find(r.id)
    r.source_id = pm2.id
    r.target_id = pm1.id
    r.save!
    assert_equal 1, pm1.reload.linked_items_count
    assert_equal 2, pm2.reload.linked_items_count
  end

  test "should cache the name of who confirmed a similar item and store confirmation information" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline!
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

  test "should move fact-check from child to parent when creating relationship if child has a fact-check but parent does not" do
    t = create_team
    child = create_project_media team: t
    create_claim_description project_media: child
    parent = create_project_media team: t
    relationship = nil

    # No report for any of them: No failure
    assert_difference 'Relationship.count' do
      assert_nothing_raised do
        relationship = create_relationship source: parent, target: child, relationship_type: Relationship.confirmed_type
      end
    end
    relationship.destroy!

    # Child has a published report, but parent doesn't: No failure; claim/fact-check/report should be moved from the child to the parent
    child = ProjectMedia.find(child.id)
    parent = ProjectMedia.find(parent.id)
    report = publish_report(child)
    claim = child.reload.claim_description
    assert_not_nil report
    assert_not_nil claim
    assert_not_nil child.reload.claim_description
    assert_not_nil child.reload.get_dynamic_annotation('report_design')
    assert_nil parent.reload.claim_description
    assert_nil parent.reload.get_dynamic_annotation('report_design')
    assert_difference 'Relationship.count' do
      assert_nothing_raised do
        relationship = create_relationship source: parent, target: child, relationship_type: Relationship.confirmed_type
      end
    end
    assert_not_nil parent.reload.claim_description
    assert_not_nil parent.reload.get_dynamic_annotation('report_design')
    assert_equal claim, parent.reload.claim_description
    assert_equal report, parent.reload.get_dynamic_annotation('report_design')
    assert_nil child.reload.claim_description
    assert_nil child.reload.get_dynamic_annotation('report_design')
    relationship.destroy!

    # Child has a published report, and parent has one too: Failure
    child = ProjectMedia.find(child.id)
    parent = ProjectMedia.find(parent.id)
    publish_report(child)
    assert_no_difference 'Relationship.count' do
      assert_raises 'ActiveRecord::RecordInvalid' do
        create_relationship source: parent, target: child, relationship_type: Relationship.confirmed_type
      end
    end
  end

  test "should belong to only one media cluster" do
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    pm4 = create_project_media team: t

    # Create a relationship between two items
    assert_difference 'Relationship.count' do
      assert_nothing_raised do
        create_relationship source_id: pm1.id, target_id: pm2.id
      end
    end

    # If an item is already a child, it can't be a child in another relationship
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_relationship source_id: pm3.id, target_id: pm2.id
      end
    end

    # If an item is already a child, it can't be a parent in another relationship
    assert_no_difference 'Relationship.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_relationship source_id: pm2.id, target_id: pm3.id
      end
    end

    # If an item is already a parent, it can't be a child in another relationship - move targets to new relationship
    assert_equal 1, Relationship.where(source_id: pm1.id).count
    assert_equal 0, Relationship.where(source_id: pm3.id).count
    create_relationship source_id: pm3.id, target_id: pm1.id
    assert_equal 0, Relationship.where(source_id: pm1.id).count
    assert_equal 2, Relationship.where(source_id: pm3.id).count

    # If an item is already a parent, it can still have another child
    assert_difference 'Relationship.count' do
      assert_nothing_raised do
        create_relationship source_id: pm3.id, target_id: pm4.id
      end
    end
  end

  # If we're trying to create a relationship between C (target_id) and B (source_id), but there is already a relationship between A (source_id) and B (target_id),
  # then, instead, create the relationship between A (source_id) and C (target_id) (so, if A's cluster contains B, then C comes in and our algorithm says C is similar
  # to B, it is added to A's cluster). Exception: If the relationship between A (source_id) and B (target_id) is a suggestion, we should not create any relationship
  # at all when trying to create a relationship between C (target_id) and B (source_id) (regardless if it’s a suggestion or a confirmed match) - but we should log that case.
  test "should add to existing media cluster" do
    t = create_team
    a = create_project_media team: t
    b = create_project_media team: t
    c = create_project_media team: t
    Relationship.create_unless_exists(a.id, b.id, Relationship.confirmed_type)
    Relationship.create_unless_exists(b.id, c.id, Relationship.confirmed_type)
    assert !Relationship.where(source: b, target: c).exists?
    assert Relationship.where(source: a, target: b).exists?
    assert Relationship.where(source: a, target: c).exists?

    a = create_project_media team: t
    b = create_project_media team: t
    c = create_project_media team: t
    Relationship.create_unless_exists(a.id, b.id, Relationship.suggested_type)
    Relationship.create_unless_exists(b.id, c.id, Relationship.confirmed_type)
    assert !Relationship.where(source: b, target: c).exists?
    assert Relationship.where(source: a, target: b).exists?
    assert !Relationship.where(source: a, target: c).exists?
  end

  test "should set current user when moving targets to new source" do
    t = create_team
    u1 = create_user is_admin: true
    u2 = create_user is_admin: true
    a = create_project_media team: t
    b = create_project_media team: t
    c = create_project_media team: t
    create_relationship source: b, target: c, user: u1
    with_current_user_and_team(u2, t) do
      create_relationship source: a, target: b
    end
    r = Relationship.where(source: a, target: c).last
    assert_equal u2, r.reload.user
  end
end
