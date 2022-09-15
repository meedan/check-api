require 'active_support/concern'

module ProjectMediaBulk
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_update(ids, updates, team)
      params = begin JSON.parse(updates[:params]).with_indifferent_access rescue {} end
      case updates[:action]
      when 'archived'
        self.bulk_archive(ids, params[:archived], params[:previous_project_id], params[:project_id], team)
      when 'move_to'
        project = Project.where(team_id: team&.id, id: params[:move_to]).last
        unless project.nil?
          self.bulk_move(ids, project, team)
          # Bulk move secondary items
          self.bulk_move_secondary_items(ids, project, team)
          # Send pusher and set parent objects for graphql
          self.send_pusher_and_parents(project, params[:previous_project_id], team)
        end
      when 'assigned_to_ids'
        self.bulk_assign(ids, params[:assigned_to_ids], params[:assignment_message], team)
      when 'update_status'
        self.bulk_update_status(ids, params[:status], team)
      end
    end

    def bulk_archive(ids, archived, previous_project_id, project_id, team)
      # Include related items
      ids.concat(Relationship.where(source_id: ids).select(:target_id).map(&:target_id))

      # SQL bulk-update
      updated_at = Time.now
      update_columns = { archived: archived, updated_at: updated_at }
      target_project = Project.where(id: project_id.to_i, team_id: team.id).last
      update_columns[:project_id] = target_project.id if archived == CheckArchivedFlags::FlagCodes::NONE && !target_project.nil?
      ProjectMedia.where(id: ids, team_id: team&.id).update_all(update_columns)

      # Enqueue in delete_forever
      if archived == CheckArchivedFlags::FlagCodes::TRASHED && !RequestStore.store[:skip_delete_for_ever]
        interval = CheckConfig.get('empty_trash_interval', 30).to_i
        options = { type: 'trash', updated_at: updated_at }
        ids.each{ |pm_id| ProjectMediaTrashWorker.perform_in(interval.days, pm_id, YAML.dump(options)) }
      end

      # Update "medias_count" cache of each list
      pids = ProjectMedia.where(id: ids).map(&:project_id).uniq
      Project.bulk_update_medias_count(pids)

      # Get a project, if any
      project_id = previous_project_id || project_id
      project = Project.where(id: project_id.to_i, team_id: team.id).last

      # Pusher
      team.notify_pusher_channel
      project&.notify_pusher_channel

      # ElasticSearch
      source = "ctx._source.archived = params.archived"
      params = { archived: archived.to_i }
      unless target_project.nil?
        source << ";ctx._source.project_id = params.project_id"
        params[:project_id] = target_project.id
      end
      script = { source: source, params: params }
      self.bulk_reindex(ids.to_json, script)

      self.update_folder_cache(ids, target_project)

      {
        team: team,
        project: project,
        check_search_project: project&.check_search_project,
        check_search_team: team.check_search_team,
        check_search_spam: team.check_search_spam,
        check_search_trash: team.check_search_trash
      }
    end

    def bulk_move(ids, project, team)
      pmp_mapping = {}
      ProjectMedia.where(id: ids).collect{ |pm| pmp_mapping[pm.id] = pm.project_id }
      # SQL bulk-update
      ProjectMedia.where(id: ids, team_id: team&.id).update_all({ project_id: project.id })

      # Update "medias_count" cache of each list
      pids = pmp_mapping.values.uniq.reject{ |v| v.nil? }
      pids << project.id
      Project.bulk_update_medias_count(pids)

      self.update_folder_cache(ids, project)

      # ElasticSearch
      script = { source: "ctx._source.project_id = params.project_id", params: { project_id: project.id } }
      self.bulk_reindex(ids.to_json, script)
    end

    def bulk_move_secondary_items(ids, project, team)
      target_ids = Relationship.where(source_id: ids).map(&:target_id)
      secondary_ids = ProjectMedia.where(id: target_ids).where.not(project_id: project.id).map(&:id)
      self.bulk_move(secondary_ids, project, team)
    end

    def send_pusher_and_parents(project, previous_project_id, team)
      # Get previous_project
      project_was = Project.find_by_id previous_project_id unless previous_project_id.blank?
      # Pusher
      team.notify_pusher_channel
      project.notify_pusher_channel
      project_was&.notify_pusher_channel
      {
        team: team,
        project: project,
        check_search_project: project&.check_search_project,
        project_was: project_was,
        check_search_project_was: project_was&.check_search_project,
        check_search_team: team.check_search_team,
        check_search_spam: team.check_search_spam,
        check_search_trash: team.check_search_trash
      }
    end

    def bulk_reindex(ids_json, script)
      ids = JSON.parse(ids_json)
      client = $repository.client
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        conflicts: 'proceed',
        body: {
          script: script,
          query: { terms: { annotated_id: ids } }
        }
      }
      client.update_by_query options
    end

    def update_folder_cache(ids, project)
      # Update "folder" cache of each list
      ids.each{ |pm_id| Rails.cache.write("check_cached_field:ProjectMedia:#{pm_id}:folder", project.title.to_s) } unless project.nil?
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

    def bulk_import_versions(versions, team_id)
      keys = versions.first.keys
      columns_sql = "(#{keys.map { |name| "\"#{name}\"" }.join(',')})"
      sql = "INSERT INTO versions_partitions.p#{team_id} #{columns_sql} VALUES "
      sql_values = []
      versions.each do |version|
        sql_values << "(#{version.values.map{|v| "'#{v}'"}.join(", ")})"
      end
      sql += sql_values.join(", ")
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, sql))
    end
  end
end
