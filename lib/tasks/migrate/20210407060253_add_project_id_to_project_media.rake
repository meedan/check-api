class ProjectMediaProject < ActiveRecord::Base
end

namespace :check do
  namespace :migrate do
    task add_project_id_to_project_media: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      ids = ProjectMediaProject.group('project_media_id').maximum(:id)
      ProjectMediaProject.where(id: ids.values).find_in_batches(:batch_size => 5000) do |pmps|
        print '.'
        es_body = []
        pmps.each do |pmp|
          print '.'
          ProjectMedia.where(id: pmp.project_media_id).update_all(project_id: pmp.project_id)
          doc_id =  Base64.encode64("ProjectMedia/#{pmp.project_media_id}")
          fields = { 'project_id' => pmp.project_id }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
