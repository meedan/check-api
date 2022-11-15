require 'active_support/concern'

module RelationshipBulk
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_update(ids, updates, team)
      if updates[:action] == 'accept'
        source_id = updates[:source_id]
        pm_source = ProjectMedia.find_by_id(source_id)
        # SQL bulk-update
        updated_at = Time.now
        update_columns = {
          relationship_type: Relationship.confirmed_type,
          updated_at: updated_at,
        }
        if User.current
          update_columns[:confirmed_at] = updated_at
          update_columns[:confirmed_by] = User.current&.id
        end
        Relationship.where(id: ids, source_id: source_id).update_all(update_columns)
        # TODO: Clear cached fields
        # Run callbacks in background
        extra_options = {
          team_id: team&.id,
          user_id: User.current&.id,
          source_id: source_id,
        }
        self.delay.run_update_callbacks(ids.to_json, extra_options.to_json)
        { source_project_media: pm_source }
      end
    end

    def run_update_callbacks(ids_json, extra_options_json)
      ids = JSON.parse(ids_json)
      extra_options = JSON.parse(extra_options_json)
      whodunnit = extra_options['user_id'].blank? ? nil : extra_options['user_id'].to_s
      team_id = extra_options['team_id']
      # Update ES
      index_alias = CheckElasticSearchModel.get_index_alias
      es_body = []      
      versions = []
      callbacks = [:reset_counters, :reset_counters, :update_counter_and_elasticsearch, :set_cluster]
      Relationship.where(id: ids, source_id: extra_options['source_id']).find_each do |r|
        # ES fields
        doc_id = Base64.encode64("ProjectMedia/#{r.target_id}")
        fields = { updated_at: r.updated_at.utc, parent_id: r.source_id }
        es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        # Add versions
        v_object = r
        v_object.relationship_type = Relationship.suggested_type.to_yaml
        v_object.confirmed_by = nil
        v_object.confirmed_at = nil
        versions << {
          item_type: 'Relationship',
          item_id: r.id.to_s,
          event: 'update',
          whodunnit: whodunnit,
          object: v_object.to_json,
          object_changes: {
            relationship_type: [Relationship.suggested_type.to_yaml, Relationship.confirmed_type.to_yaml],
            confirmed_by: [nil, whodunnit],
            confirmed_at: [nil, updated_at],
          }.to_json,
          created_at: r.updated_at,
          meta: r.version_metadata,
          event_type: 'update_relationship',
          object_after: r.to_json,
          associated_id: r.target_id,
          associated_type: 'ProjectMedia',
          team_id: team_id
        }
        callbacks.each do |callback|
          r.send(callback)
        end
      end
      # Update ES docs
      $repository.client.bulk body: es_body unless es_body.blank?
      # Import versions
      bulk_import_versions(versions, team_id) if versions.size > 0
    end
  end
end