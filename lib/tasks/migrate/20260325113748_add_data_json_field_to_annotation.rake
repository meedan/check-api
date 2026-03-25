namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:migrate_tags_data_json
    task migrate_tags_data_json: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:migrate_tags_data_json') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "\nProcessing team #{team.slug} ....\n"
        team.project_medias.find_in_batches(batch_size: 1000) do |pms|
          print '.'
          ids = pms.pluck(:id)
          tag_items = []
          Tag.where(annotation_type: 'tag', annotated_type: 'ProjectMedia', annotated_id: ids)
          .find_each do |tag|
            print '.'
            tag.data_json = tag.data
            tag_items << tag.attributes
          end
          Tag.upsert_all(tag_items) unless tag_items.blank?
        end
        Rails.cache.write('check:migrate:migrate_tags_data_json', team.id)
      end
    end
  end
end