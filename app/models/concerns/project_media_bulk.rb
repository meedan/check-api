require 'active_support/concern'

module ProjectMediaBulk
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_update(ids, updates, team)
      params = begin JSON.parse(updates[:params]).with_indifferent_access rescue {} end
      case updates[:action]
      when 'archived'
        self.bulk_archive(ids, params[:archived], team)
      when 'assigned_to_ids'
        self.bulk_assign(ids, params[:assigned_to_ids], params[:assignment_message], team)
      when 'update_status'
        self.bulk_update_status(ids, params[:status], team)
      when 'remove_tags'
        self.bulk_remove_tags(ids, params[:tags_text], team)
      end
    end

    def bulk_archive(ids, archived, team)
      # Include related items
      ids.concat(Relationship.where(source_id: ids).select(:target_id).map(&:target_id))

      # SQL bulk-update
      updated_at = Time.now
      update_columns = { archived: archived, updated_at: updated_at }
      ProjectMedia.where(id: ids, team_id: team&.id).update_all(update_columns)

      # Enqueue in delete_forever
      if archived == CheckArchivedFlags::FlagCodes::TRASHED && !RequestStore.store[:skip_delete_for_ever]
        interval = CheckConfig.get('empty_trash_interval', 30).to_i
        options = { type: 'trash', updated_at: updated_at.to_i }
        ids.each{ |pm_id| ProjectMediaTrashWorker.perform_in(interval.days, pm_id, YAML.dump(options)) }
      end

      # ElasticSearch
      source = "ctx._source.archived = params.archived"
      params = { archived: archived.to_i }
      script = { source: source, params: params }
      self.bulk_reindex(ids.to_json, script)

      {
        team: team,
        check_search_team: team.check_search_team,
        check_search_spam: team.check_search_spam,
        check_search_trash: team.check_search_trash
      }
    end

    def bulk_reindex(ids_json, script)
      ids = JSON.parse(ids_json)
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        conflicts: 'proceed',
        body: {
          script: script,
          query: { terms: { annotated_id: ids } }
        }
      }
      $repository.client.update_by_query options
    end

    def bulk_assign(ids, assigned_to_ids, assignment_message, team)
      status_mapping = {}
      statuses = Annotation.where(annotated_type: 'ProjectMedia', annotation_type: 'verification_status', annotated_id: ids)
      status_ids = statuses.map(&:id)
      statuses.collect{ |s| status_mapping[s.id] = s.annotated_id }
      # Get current assignments
      assignment_mapping = Hash.new {|hash, key| hash[key] = [] }
      Assignment.where(assigned_type: 'Annotation', assigned_id: status_ids).find_each do |a|
        assignment_mapping[a.assigned_id] << a.user_id
      end
      # Bulk-insert assignments
      assigner_id = User.current.nil? ? nil : User.current.id
      assigned_ids = assigned_to_ids.to_s.split(',').map(&:to_i)
      # Verify that users aleady exists
      u_ids = team.team_users.where(user_id: assigned_ids).map(&:user_id)
      inserts = []
      status_ids.each do |s_id|
        u_ids.each do |u_id|
          inserts << {
            assigned_type: 'Annotation', assigned_id: s_id, user_id: u_id, assigner_id: assigner_id, message: assignment_message
          } unless assignment_mapping[s_id].include?(u_id)
        end
      end
      result = Assignment.import inserts, validate: false, recursive: false, timestamps: true
      # Run callbacks in background
      extra_options = {
        team_id: team&.id,
        user_id: User.current&.id,
        assigned_ids: u_ids
      }
      self.delay.run_bulk_assignment_create_callbacks(result.ids.map(&:to_i).to_json, status_mapping.to_json, extra_options.to_json, User.current)
      { team: team }
    end

    def run_bulk_assignment_create_callbacks(ids_json, status_mapping_json, extra_options_json, current_user = User.current)
      User.current ||= current_user
      ids = JSON.parse(ids_json)
      status_mapping = JSON.parse(status_mapping_json)
      extra_options = JSON.parse(extra_options_json)
      whodunnit = extra_options['user_id'].blank? ? nil : extra_options['user_id'].to_s
      team_id = extra_options['team_id']
      assigned_users = []
      User.where(id: extra_options['assigned_ids']).collect{ |u| assigned_users[u.id] = u.name }
      versions = []
      callbacks = [
        :send_email_notification_on_create,
        :increase_assignments_count,
        :propagate_assignments,
        :apply_rules_and_actions,
        :update_elasticsearch_assignment
      ]
      ids.each do |id|
        a = Assignment.find_by_id(id)
        unless a.nil?
          versions << {
            item_type: 'Assignment',
            item_id: a.id.to_s,
            event: 'create',
            whodunnit: whodunnit,
            object: nil,
            object_changes: {
              assigned_type: [nil, 'Annotation'], assigned_id: [nil, a.assigned_id], user_id: [nil, a.user_id],
              message: [nil, a.message], assigner_id: [nil, a.assigner_id]
            }.to_json,
            created_at: a.created_at,
            meta: {
              type: 'media',
              user_name: assigned_users[a.user_id],
            }.to_json,
            event_type: 'create_assignment',
            object_after: a.to_json,
            associated_id: status_mapping[a.assigned_id.to_s],
            associated_type: 'ProjectMedia',
            team_id: team_id
          }
          callbacks.each do |callback|
            a.send(callback)
          end
        end
      end
      bulk_import_versions(versions, team_id) if versions.size > 0
    end

    def bulk_update_status(ids, status, team)
      ids.map!(&:to_i)
      # Exclude published reports
      excluded_ids = []
      Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: ids).find_each do |a|
        published = begin (a.read_attribute(:data)['state'] == 'published') rescue false end
        excluded_ids << a.annotated_id if published
      end
      # Bulk-update status
      ids -= excluded_ids
      status_mapping = {}
      statuses = Annotation.where(annotated_type: 'ProjectMedia', annotation_type: 'verification_status', annotated_id: ids)
      status_ids = statuses.map(&:id)
      statuses.collect{ |s| status_mapping[s.id] = s.annotated_id }
      DynamicAnnotation::Field.where(
        field_name: "verification_status_status", annotation_type: "verification_status", annotation_id: status_ids
      ).update_all(value: status)
      # Update cache
      ids.each{ |pm_id| Rails.cache.write("check_cached_field:ProjectMedia:#{pm_id}:status", status) }
      # ElasticSearch update
      script = { source: "ctx._source.verification_status = params.verification_status", params: { verification_status: status } }
      self.bulk_reindex(ids.to_json, script)
      # Run callbacks in background
      extra_options = { team_id: team&.id, user_id: User.current&.id, status: status }
      self.delay.run_bulk_status_callbacks(status_ids.to_json, status_mapping.to_json, extra_options.to_json)
      { team: team, check_search_team: team.check_search_team }
    end

    def run_bulk_status_callbacks(ids_json, status_mapping_json, extra_options_json)
      ids = JSON.parse(ids_json)
      status_mapping = JSON.parse(status_mapping_json)
      extra_options = JSON.parse(extra_options_json)
      whodunnit = extra_options['user_id'].blank? ? nil : extra_options['user_id'].to_s
      team_id = extra_options['team_id']
      versions = []
      callbacks = [:apply_rules, :update_report_design_if_needed, :replicate_status_to_children, :send_message]
      DynamicAnnotation::Field.where(
        field_name: "verification_status_status", annotation_type: "verification_status", annotation_id: ids
      ).find_each do |f|
        versions << {
          item_type: 'DynamicAnnotation::Field',
          item_id: f.id.to_s,
          event: 'update',
          whodunnit: whodunnit,
          object: f.to_json,
          object_changes: { value: [nil, "#{extra_options['status']}"]}.to_json,
          created_at: f.created_at,
          event_type: 'update_dynamicannotationfield',
          object_after: f.to_json,
          associated_id: status_mapping[f.annotation_id.to_s],
          associated_type: 'ProjectMedia',
          team_id: team_id
        }
        callbacks.each do |callback|
          f.send(callback)
        end
      end
      bulk_import_versions(versions, team_id) if versions.size > 0
    end

    def bulk_remove_tags(ids, tags_text, team)
      tag_text_ids = tags_text.to_s.split(',').map(&:to_i)
      tags_c = tag_text_ids.collect{|id| { tag: id }.with_indifferent_access.to_yaml }
      # Load tags
      tags = Tag.where(annotation_type: 'tag', annotated_type: 'ProjectMedia', annotated_id: ids).where('data IN (?)', tags_c)
      tag_pm = {}
      tags.each{ |t| tag_pm[t.id] = t.annotated_id }
      tags.delete_all
      # clear cached field
      ids.each{ |pm_id| Rails.cache.delete("check_cached_field:ProjectMedia:#{pm_id}:tags_as_sentence") }
      self.delay.run_bulk_remove_tags_callbacks(ids.to_json, tag_text_ids.to_json, tag_pm.to_json)
      { team: team, check_search_team: team.check_search_team }
    end

    def run_bulk_remove_tags_callbacks(ids_json, tag_text_ids_json, tag_pm_json)
      ids = JSON.parse(ids_json)
      tag_text_ids = JSON.parse(tag_text_ids_json)
      tag_pm = JSON.parse(tag_pm_json)
      # update ES
      tag_pm.each do |t_id, pm_id|
        options = { es_type: 'tags', doc_id: Base64.encode64("ProjectMedia/#{pm_id}"), model_id: t_id.to_i }
        Tag.destroy_elasticsearch_doc_nested(options)
      end
      # Update tags count
      TagText.where(id: tag_text_ids).find_each do |tag_text|
        tag_text.update_column(:tags_count, tag_text.calculate_tags_count)
      end
      # Update tags_as_sentence cached field
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      es_body = []
      field_name = 'tags_as_sentence'
      ProjectMedia.where(id: ids).find_each do |pm|
        value = pm.send(field_name, true)
        field_value = value.split(', ').size
        fields = { "#{field_name}" => field_value }
        doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
        es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
      end
      client.bulk body: es_body unless es_body.blank?
    end

    def bulk_mark_read(ids, read, team)
      read_value = read.with_indifferent_access[:read]
      pm_ids = ProjectMedia.where(id: ids).where.not(read: read_value).map(&:id)
      # SQL bulk-update
      updated_at = Time.now
      update_columns = { read: read_value, updated_at: updated_at }
      ProjectMedia.where(id: pm_ids, team_id: team&.id).update_all(update_columns)
      # ElasticSearch
      script = { source: "ctx._source.read = params.read", params: { read: read_value.to_i } }
      self.bulk_reindex(pm_ids.to_json, script)
      # Run callbacks in background
      self.delay.run_bulk_mark_read_callbacks(pm_ids.to_json)
      { team: team }
    end

    def run_bulk_mark_read_callbacks(ids_json)
      ids = JSON.parse(ids_json)
      ProjectMedia.where(id: ids).find_each do |pm|
        pm.apply_rules_and_actions_on_update
      end
    end
  end
end
