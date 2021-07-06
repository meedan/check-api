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
          self.bulk_move_secondary_items(ids, project, updates[:previous_project_id], team)
          # send pusher and set parent objects for graphql
          self.send_pusher_and_parents(project, updates[:previous_project_id], team)
        end
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

      # Other callbacks to run in background
      ProjectMedia.delay.run_bulk_update_team_tasks(pmp_mapping, User.current&.id)

      # ElasticSearch
      script = { source: "ctx._source.project_id = params.project_id", params: { project_id: project.id } }
      self.bulk_reindex(ids.to_json, script)
    end

    def bulk_move_secondary_items(ids, project, previous_project_id, team)
      target_ids = Relationship.where(source_id: ids).map(&:target_id)
      secondary_ids = ProjectMedia.where(id: target_ids).where.not(project_id: project.id)
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
  end
end
