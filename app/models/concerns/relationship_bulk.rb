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
        relationships = Relationship.where(id: ids, source_id: source_id)
        relationships.update_all(update_columns)
        # Move targets to a specific project.
        unless updates[:add_to_project_id].blank?
          target_ids = relationships.map(&:target_id)
          ProjectMedia.bulk_update(target_ids, { action: 'move_to', params: { move_to: updates[:add_to_project_id] }.to_json }, team)
        end
        # Clear cached fields
        cached_fields = ['linked_items_count', 'suggestions_count', 'report_status', 'demand', 'last_seen']
        cached_fields.each do |name|
          Rails.cache.delete("check_cached_field:ProjectMedia:#{pm_source.id}:#{name}")
          ids.each { |id| Rails.cache.delete("check_cached_field:ProjectMedia:#{id}:#{name}") }
        end
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

    def bulk_destroy(ids, updates, team)
      source_id = updates[:source_id]
      pm_source = ProjectMedia.find_by_id(source_id)
      relationships = Relationship.where(id: ids, source_id: source_id)
      relationship_target = {}
      relationships.find_each{ |r| relationship_target[r.id] = r.target_id}
      relationships.delete_all
      # Run callbacks in background
      extra_options = {
        team_id: team&.id,
        user_id: User.current&.id,
        source_id: source_id,
      }
      self.delay.run_destroy_callbacks(relationship_target.to_json, extra_options.to_json)
      { source_project_media: pm_source }
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
      callbacks = [:reset_counters, :update_counters, :set_cluster]
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
            confirmed_at: [nil, r.updated_at],
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

    def run_destroy_callbacks(relationship_target_json, extra_options_json)
      relationship_target = JSON.parse(relationship_target_json)
      extra_options = JSON.parse(extra_options_json)
      target_ids = relationship_target.values
      whodunnit = extra_options['user_id'].blank? ? nil : extra_options['user_id'].to_s
      team_id = extra_options['team_id']
      source_id = extra_options['source_id']
      # update_counters (destroy callback)
      source = ProjectMedia.find_by_id(source_id)
      version_metadata = nil
      unless source.nil?
        source.skip_check_ability = true
        source.targets_count = Relationship.where(source_id: source.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
        source.save!
        # Get version metadata
        version_metadata = {
          source: {
            title: source.title,
            type: source.report_type,
            url: source.full_url,
            by_check: false,
          }
        }.to_json
      end

      ProjectMedia.where(id: target_ids).find_each do |target|
        target.skip_check_ability = true
        target.sources_count = Relationship.where(target_id: target.id).where('relationship_type = ?', Relationship.confirmed_type.to_yaml).count
        target.save!
      end
      # Update ES
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        conflicts: 'proceed'
      }
      body = {
        script: { source: "ctx._source.updated_at = params.updated_at", params: { updated_at: Time.now.utc } },
        query: { terms: { annotated_id: target_ids } }
      }
      options[:body] = body
      $repository.client.update_by_query options
      versions = []
      relationship_target.each do |r_id, target_id|
        # Add versions
        v_object = Relationship.new(id: r_id, source_id: source_id, target_id: target_id)
        v_object.relationship_type = Relationship.suggested_type.to_yaml
        v_object.confirmed_by = nil
        v_object.confirmed_at = nil
        versions << {
          item_type: 'Relationship',
          item_id: r_id.to_s,
          event: 'destroy',
          whodunnit: whodunnit,
          object: v_object.to_json,
          meta: version_metadata,
          event_type: 'destroy_relationship',
          associated_id: target_id,
          associated_type: 'ProjectMedia',
          team_id: team_id
        }
      end
      # Import versions
      bulk_import_versions(versions, team_id) if versions.size > 0
    end
  end
end
