namespace :check do
  namespace :migrate do
    task unpublish_items_without_fact_check: :environment do
      started = Time.now.to_i
      RequestStore.store[:skip_notifications] = true
      last_team_id = Rails.cache.read('check:migrate:unpublish_items_without_fact_check:team_id') || 0
      log_items = []
      failed_items = []
      Team.where('id > ?', last_team_id).find_each do |team|
        print '.'
        total = 0
        team.project_medias.find_in_batches(:batch_size => 1000) do |pms|
          pm_ids = pms.map(&:id)
          # Get published items
          published_ids = Annotation.where(
            annotation_type: "report_design",
            annotated_type: "ProjectMedia",
            annotated_id: pm_ids
          ).select{ |a| a.data['state'] == 'published'}.map(&:annotated_id)
          # Get items with fact checks
          fact_checks_ids = ProjectMedia.where(id: published_ids)
          .joins('INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id')
          .joins('INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id').map(&:id)
          # Get published items without fact checks
          diff = published_ids - fact_checks_ids
          unless diff.empty?
            Dynamic.where(
              annotation_type: "report_design",
              annotated_type: "ProjectMedia",
              annotated_id: diff
            ).find_each do |a|
              print '.'
              new_data = a.data
              new_data['state'] = 'unpublished'
              a.data = new_data
              begin a.save! rescue failed_items << a.id end
            end
            total += diff.length 
          end
        end
        unless total == 0
          log_items << { team_slug: team.slug, total: total }  
        end
        Rails.cache.write('check:migrate:unpublish_items_without_fact_check:team_id', team.id)
      end
      RequestStore.store[:skip_notifications] = false
      puts "Logs data is: #{log_items.inspect}" if log_items.length > 0
      puts "Failed items: #{failed_items.inspect}" if failed_items.length > 0
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end