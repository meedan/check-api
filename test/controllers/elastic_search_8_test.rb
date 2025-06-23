require_relative '../test_helper'

class ElasticSearch8Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should filter by linked_items_count, suggestions_count and demand numeric range" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    [:linked_items_count, :suggestions_count, :demand].each do |field|
      query = { "#{field}": { max: 5 } }
      query[field][:min] = 0
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 0, result.medias.count
    end
    pm1 = create_project_media team: t, quote: 'Test A', disable_es_callbacks: false
    pm2 = create_project_media team: t, quote: 'Test B', disable_es_callbacks: false
    pm3 = create_project_media team: t, quote: 'Test C', disable_es_callbacks: false

    # Add linked items
    t_pm2 = create_project_media team: t
    t_pm3 = create_project_media team: t
    t2_pm3 = create_project_media team: t
    create_relationship source_id: pm2.id, target_id: t_pm2.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: pm3.id, target_id: t_pm3.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: pm3.id, target_id: t2_pm3.id, relationship_type: Relationship.confirmed_type

    # Add suggested items
    t_pm2 = create_project_media team: t, quote: 'Test D', disable_es_callbacks: false
    t_pm3 = create_project_media team: t, quote: 'Test E', disable_es_callbacks: false
    t2_pm3 = create_project_media team: t, quote: 'Test F', disable_es_callbacks: false
    create_relationship source_id: pm2.id, target_id: t_pm2.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: pm3.id, target_id: t_pm3.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: pm3.id, target_id: t2_pm3.id, relationship_type: Relationship.suggested_type

    # Add requests
    create_tipline_request team_id: t.id, associated: pm2
    2.times { create_tipline_request(team_id: t.id, associated: pm3) }
    sleep 2

    min_mapping = {
      "0": [pm1.id, pm2.id, pm3.id, t_pm2.id, t_pm3.id, t2_pm3.id],
      "1": [pm2.id, pm3.id],
      "2": [pm3.id],
      "3": [],
    }
    # query with numeric range only
    [:suggestions_count, :demand].each do |field|
      query = { "#{field}": { max: 5 } }
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json, nil, t.id)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
      # query with numeric range and keyword
      query[:keyword] = 'Test'
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json, nil, t.id)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
      # Query with max and min
      query[field][:min] = 1
      query[field][:max] = 2
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm2.id, pm3.id].sort, result.medias.map(&:id).sort
    end
    # Verify linked_items_count
    min_mapping = {
      "1": [pm1.id, pm2.id, pm3.id, t_pm2.id, t_pm3.id, t2_pm3.id],
      "2": [pm2.id, pm3.id],
      "3": [pm3.id],
      "4": [],
    }
    # query with numeric range only
    [:linked_items_count].each do |field|
      query = { "#{field}": { max: 5 } }
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json, nil, t.id)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
      # query with numeric range and keyword
      query[:keyword] = 'Test'
      min_mapping.each do |min, items|
        query[field][:min] = min.to_s
        result = CheckSearch.new(query.to_json, nil, t.id)
        assert_equal items.sort, result.medias.map(&:id).sort
      end
      # Query with max and min
      query[field][:min] = 2
      query[field][:max] = 3
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm2.id, pm3.id].sort, result.medias.map(&:id).sort
    end
  end

  # Please add new tests to test/controllers/elastic_search_9_test.rb
end
