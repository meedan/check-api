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
      # replace `copy_to_project` action with `move_to_project`
      Team.find_each do |t|
        if t.settings && t.settings.keys.include?(:rules)
          print '.'
          new_settings = t.settings
          rules_json = t.settings[:rules].to_json
          rules_json.gsub!('copy_to_project', 'move_to_project')
          new_settings[:rules] = JSON.parse(rules_json)
          t.update_columns(settings: new_settings)
        end
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
