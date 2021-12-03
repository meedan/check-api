require_relative '../test_helper'

class ElasticSearch8Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
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
end
