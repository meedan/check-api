class ProjectSource < ActiveRecord::Base

end

class ClaimSource < ActiveRecord::Base

end

namespace :check do
  namespace :migrate do
    task remove_project_source: :environment do
      client = MediaSearch.gateway.client
      options = {
        index: CheckElasticSearchModel.get_index_name,
        type: 'media_search',
        conflicts: 'proceed'
      }
      ProjectSource.find_in_batches(:batch_size => 2500) do |data|
        print "."
        ids = data.map(&:id)
        Annotation.where(id: ids, annotated_type: 'ProjectSource').delete_all
        ProjectSource.where(id: ids).delete_all
        body = {
          query: {
            bool: {
              must: [
                { terms: { annotated_id: ids } },
                { term: { annotated_type: { value: "projectsource" } } }
              ]
            }
          }
        }
        options[:body] = body
        client.delete_by_query options
      end
      Team.find_each do |t|
        Version.from_partition(t.id).where(item_type: 'ProjectSource')
        .find_in_batches(:batch_size => 2500) do |versions|
          print "."
          Version.from_partition(t.id).where(id: versions.map(&:id)).delete_all
        end
      end
      # Remove Cache - project_source_id_cache_for_project_media_*
      Rails.cache.delete_matched('project_source_id_cache_for_project_media_*')
      # Remove ClaimSource
      ClaimSource.find_in_batches(:batch_size => 2500) do |data|
        print "."
        ids = data.map(&:id)
        # remove un-needed sources
        s_ids = data.map(&:source_id)
        s_ids -= AccountSource.where(source_id: s_ids).map(&:source_id)
        s_ids -= User.where(source_id: s_ids).map(&:source_id)
        # delete annotations
        Annotation.where(id: s_ids, annotated_type: 'Source').delete_all
        # delete versions
        Team.find_each do |t|
          Version.from_partition(t.id).where(item_type: 'Source', item_id: s_ids)
          .find_in_batches(:batch_size => 2500) do |versions|
            print "."
            Version.from_partition(t.id).where(id: versions.map(&:id)).delete_all
          end
        end
        Source.where(id: s_ids).delete_all
        ClaimSource.where(id: ids).delete_all
      end
    end
  end
end
