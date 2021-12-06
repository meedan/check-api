require_relative '../test_helper'

class ElasticSearch8Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should filter items by non project and read-unread" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media project: p, disable_es_callbacks: false
      pm3 = create_project_media team: t, quote: 'claim a', disable_es_callbacks: false
      results = CheckSearch.new({ projects: ['-1'] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ projects: [p.id, '-1'] }.to_json)
      assert_equal [pm.id, pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'claim', projects: ['-1'] }.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
      # test read/unread
      pm.read = true
      pm.save!
      results = CheckSearch.new({ read: ['1'] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ read: ['0'] }.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ keyword: 'claim', read: ['0'] }.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
    end
  end

  test "should sort items by creator name" do
    t = create_team
    p = create_project team: t
    # create users with capital and small letters to verify sort with case insensitive
    u1 = create_user name: 'ahmad'
    u2 = create_user name: 'Ali'
    u3 = create_user name: 'Zahra'
    u4 = create_user name: 'Zein'
    create_team_user team: t, user: u1
    create_team_user team: t, user: u2
    create_team_user team: t, user: u3
    create_team_user team: t, user: u4
    RequestStore.store[:skip_cached_field_update] = false
    pm1 = create_project_media project: p, user: u1
    pm2 = create_project_media project: p, user: u2
    pm3 = create_project_media project: p, user: u3
    pm4 = create_project_media project: p, user: u4
    sleep 2
    result = CheckSearch.new({ projects: [p.id], sort: 'creator_name', sort_type: 'asc' }.to_json)
    assert_equal [pm1.id, pm2.id, pm3.id, pm4.id], result.medias.map(&:id)
    result = CheckSearch.new({ projects: [p.id], sort: 'creator_name', sort_type: 'desc' }.to_json)
    assert_equal [pm4.id, pm3.id, pm2.id, pm1.id], result.medias.map(&:id)
  end

  [:linked_items_count, :suggestions_count, :demand].each do |field|
    test "should filter by #{field} numeric range" do
      RequestStore.store[:skip_cached_field_update] = false
      p = create_project
      query = { projects: [p.id], "#{field}": { max: 5 } }
      query[field][:min] = 0
      result = CheckSearch.new(query.to_json)
      assert_equal 0, result.medias.count
      pm1 = create_project_media project: p, quote: 'Test A', disable_es_callbacks: false
      pm2 = create_project_media project: p, quote: 'Test B', disable_es_callbacks: false
      pm3 = create_project_media project: p, quote: 'Test C', disable_es_callbacks: false

      # Add linked items
      t_pm2 = create_project_media project: p
      t_pm3 = create_project_media project: p
      t2_pm3 = create_project_media project: p
      create_relationship source_id: pm2.id, target_id: t_pm2.id, relationship_type: Relationship.confirmed_type
      create_relationship source_id: pm3.id, target_id: t_pm3.id, relationship_type: Relationship.confirmed_type
      create_relationship source_id: pm3.id, target_id: t2_pm3.id, relationship_type: Relationship.confirmed_type

      # Add suggested items
      t_pm2 = create_project_media project: p
      t_pm3 = create_project_media project: p
      t2_pm3 = create_project_media project: p
      create_relationship source_id: pm2.id, target_id: t_pm2.id, relationship_type: Relationship.suggested_type
      create_relationship source_id: pm3.id, target_id: t_pm3.id, relationship_type: Relationship.suggested_type
      create_relationship source_id: pm3.id, target_id: t2_pm3.id, relationship_type: Relationship.suggested_type

      # Add requests
      create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
      create_dynamic_annotation annotation_type: 'smooch', annotated: pm2
      2.times { create_dynamic_annotation(annotation_type: 'smooch', annotated: pm3) }

      sleep 2

      min_mapping = {
        "0": [pm1.id, pm2.id, pm3.id],
        "1": [pm2.id, pm3.id],
        "2": [pm3.id],
        "3": [],
      }

      # query with numeric range only
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
      # query with numeric range and keyword
      query[:keyword] = 'Test'
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
      # Query with max and min
      query[field][:min] = 1
      query[field][:max] = 2
      result = CheckSearch.new(query.to_json)
      assert_equal [pm2.id, pm3.id].sort, result.medias.map(&:id).sort
    end
  end

  test "should search by numeric range for tasks" do
    number = create_field_type field_type: 'number', label: 'Number'
    at = create_annotation_type annotation_type: 'task_response_number', label: 'Task Response Number'
    create_field_instance annotation_type_object: at, name: 'response_number', label: 'Response', field_type_object: number, optional: true
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'number'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.response = { annotation_type: 'task_response_number', set_fields: { response_number: 2 }.to_json }.to_json
      pm2_tt.save!
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt.response = { annotation_type: 'task_response_number', set_fields: { response_number: 4 }.to_json }.to_json
      pm3_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 2 }}]}.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 2, max: 5 }}]}.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 2, max: 3 }}]}.to_json)
      assert_equal [pm2.id], results.medias.map(&:id)
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 3, max: 5 }}]}.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
    end
  end
end
