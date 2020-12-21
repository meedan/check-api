namespace :check do
  namespace :migrate do
    task remove_pmp_from_trashed_unconfirmed_items: :environment do
      started = Time.now.to_i
      client = $repository.client
      options = { index: CheckElasticSearchModel.get_index_alias }
      [CheckArchivedFlags::FlagCodes::TRASHED, CheckArchivedFlags::FlagCodes::UNCONFIRMED].each do |archived|
        ProjectMediaProject.joins("INNER JOIN project_medias pm ON project_media_projects.project_media_id = pm.id")
        .where("pm.archived = ?", archived).find_in_batches(batch_size: 3000) do |pmps|
          print "."
          ids = pmps.map(&:id)
          pids = pmps.map(&:project_id)
          # Bulk-delete in a single SQL
          ProjectMediaProject.where(id: ids).delete_all
          # Bulk-update medias count of each project
          Project.bulk_update_medias_count(pids)
          # Bulk-update elastic search
          pm_ids = pmps.map(&:project_media_id)
          body = {
            script: {
              source: "ctx._source.project_id = params.ids;ctx._source.archived = params.archived", params: { ids: [], archived: archived }
            },
            query: { terms: { annotated_id: pm_ids } }
          }
          options[:body] = body
          client.update_by_query options
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
