require 'active_support/concern'

module ProjectMediaBulk
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_update(ids, updates, team)
      keys = updates.keys.map(&:to_sym)
      if keys.include?(:archived)
        self.bulk_archive(ids, updates[:archived], updates[:previous_project_id], updates[:project_id], team)
      elsif keys.include?(:move_to)
        project = Project.where(team_id: team&.id, id: updates[:move_to]).last
        unless project.nil?
          self.bulk_move(ids, project, team)
          # bulk move secondary items
          self.bulk_move_secondary_items(ids, project, team)
          # send pusher and set parent objects for graphql
          self.send_pusher_and_parents(project, updates[:previous_project_id], team)
        end
      elsif keys.include?(:assigned_to_ids)
        self.bulk_assign(ids, updates[:assigned_to_ids], updates[:assignment_message], team)
      end
    end

    def bulk_archive(ids, archived, previous_project_id, project_id, team)
      # Include related items
      ids.concat(Relationship.where(source_id: ids).select(:target_id).map(&:target_id))

      # SQL bulk-update
      update_columns = { archived: archived }
      update_columns[:project_id] = project_id if archived == CheckArchivedFlags::FlagCodes::NONE && !project_id.blank?
      ProjectMedia.where(id: ids, team_id: team&.id).update_all(update_columns)

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
      script = { source: "ctx._source.archived = params.archived", params: { archived: archived.to_i } }
      self.bulk_reindex(ids.to_json, script)

      { team: team, project: project, check_search_project: project&.check_search_project, check_search_team: team.check_search_team, check_search_trash: team.check_search_trash }
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

      # Update "folder" cache of each list
      ids.each{|pm_id| Rails.cache.write("check_cached_field:ProjectMedia:#{pm_id}:folder", project.title.to_s)}

      # Other callbacks to run in background
      ProjectMedia.delay.run_bulk_update_team_tasks(pmp_mapping, User.current&.id)

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
      { team: team, project: project, check_search_project: project&.check_search_project,
        project_was: project_was, check_search_project_was: project_was&.check_search_project,
        check_search_team: team.check_search_team, check_search_trash: team.check_search_trash
      }
    end

    def run_bulk_update_team_tasks(pmp_mapping, user_id)
      ids = pmp_mapping.keys
      current_user = User.current
      User.current = User.find_by_id(user_id.to_i)
      ids.each do |id|
        pm = ProjectMedia.find(id)
        if pm.project_id != pmp_mapping[pm.id]
          # remove existing team tasks based on old project_id
          pm.remove_related_team_tasks_bg(pmp_mapping[pm.id]) unless pmp_mapping[pm.id].blank?
          # add new team tasks based on new project_id
          pm.add_destination_team_tasks(pm.project_id)
        end
      end
      User.current = current_user
    end

    def bulk_reindex(ids_json, script)
      ids = JSON.parse(ids_json)
      client = $repository.client
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        body: {
          script: script,
          query: { terms: { annotated_id: ids } }
        }
      }
      client.update_by_query options
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
      # verify that users aleady exists
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
      self.delay.run_bulk_assignment_create_callbacks(result.ids.map(&:to_i).to_json, status_mapping.to_json, extra_options.to_json)
      { team: team }
    end

    def run_bulk_assignment_create_callbacks(ids_json, status_mapping_json, extra_options_json)
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
      if versions.size > 0
        keys = versions.first.keys
        columns_sql = "(#{keys.map { |name| "\"#{name}\"" }.join(',')})"
        sql = "INSERT INTO versions_partitions.p#{team_id} #{columns_sql} VALUES "
        sql_values = []
        versions.each do |version|
          sql_values << "(#{version.values.map{|v| "'#{v}'"}.join(", ")})"
        end
        sql += sql_values.join(", ")
        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
