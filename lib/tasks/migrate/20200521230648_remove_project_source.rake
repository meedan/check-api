namespace :check do
  namespace :migrate do
    task remove_project_source: :environment do
      client = $repository.client
      options = {
        index: CheckElasticSearchModel.get_index_name,
        type: 'media_search',
        conflicts: 'proceed'
      }
      Annotation.where(annotated_type: 'ProjectSource').find_in_batches(:batch_size => 2500) do |data|
        print "."
        ids = data.map(&:id)
        Annotation.where(id: ids).delete_all
      end
      Team.find_each do |t|
        Version.from_partition(t.id).where(item_type: 'ProjectSource')
        .find_in_batches(:batch_size => 2500) do |versions|
          print "."
          Version.from_partition(t.id).where(id: versions.map(&:id)).delete_all
          body = {
            query: {
              bool: {
                must: [
                  { term: { team_id: { value: t.id } } },
                  { term: { annotated_type: { value: "projectsource" } } }
                ]
              }
            }
          }
          options[:body] = body
          client.delete_by_query options
        end
      end
      # Remove Cache - project_source_id_cache_for_project_media_*
      Rails.cache.delete_matched('project_source_id_cache_for_project_media_*')
    end
  end
end
