require 'active_support/concern'

module ProjectMediaBulk
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_update(ids, updates, team)
      keys = updates.keys.map(&:to_sym)
      if keys.include?(:archived)
        self.bulk_archive(ids, updates[:archived], updates[:previous_project_id], updates[:project_id], team)
      elsif keys.include?(:move_to)
        self.bulk_move(ids, updates[:move_to], updates[:previous_project_id], team)
      end
    end

    def bulk_archive(ids, archived, previous_project_id, project_id, team)
      # Include related items
      ids.concat(Relationship.where(source_id: ids).select(:target_id).map(&:target_id))

      # SQL bulk-update
      ProjectMedia.where(id: ids, team_id: team&.id).update_all({ archived: archived })

      # Update "medias_count" cache of each list
      # TODO: Sawy - review

      # Get a project, if any
      project_id = previous_project_id || project_id
      project = Project.where(id: project_id.to_i, team_id: team.id).last

      # Pusher
      team.notify_pusher_channel
      project&.notify_pusher_channel

      # ElasticSearch
      updates = { archived: archived.to_i }
      updates.merge!({ project_id: [project_id]}) unless project_id.blank?
      self.bulk_reindex(ids.to_json, updates)

      { team: team, project: project, check_search_project: project&.check_search_project, check_search_team: team.check_search_team, check_search_trash: team.check_search_trash }
    end

    def bulk_move(ids, project_id, previous_project_id, team)
      # SQL bulk-update
      ProjectMedia.where(id: ids, team_id: team&.id).update_all({ project_id: project_id })

      # Update "medias_count" cache of each list
      # TODO: Sawy - review

      # Get a project, if any
      project = Project.where(id: project_id.to_i, team_id: team.id).last

      # Pusher
      team.notify_pusher_channel
      project&.notify_pusher_channel

      # ElasticSearch
      updates = { project_id: project_id.to_i }
      self.bulk_reindex(ids.to_json, updates)

      { team: team, project: project, check_search_project: project&.check_search_project, check_search_team: team.check_search_team, check_search_trash: team.check_search_trash }
    end

    def bulk_reindex(ids_json, updates)
      ids = JSON.parse(ids_json)
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      es_body = []
      ids.each do |id|
        model = ProjectMedia.new(id: id)
        doc_id = model.get_es_doc_id(model)
        if $repository.exists?(doc_id)
          es_body << { update: { _index: index_alias, _id: doc_id, data: { doc: updates } } }
        else
          model.create_elasticsearch_doc_bg(nil)
        end
      end
      client.bulk body: es_body unless es_body.blank?
    end
  end
end
