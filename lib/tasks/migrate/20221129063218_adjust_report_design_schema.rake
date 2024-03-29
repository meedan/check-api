namespace :check do
  namespace :migrate do
    task adjust_report_design_schema: :environment do
      started = Time.now.to_i
      RequestStore.store[:skip_rules] = true
      last_team_id = Rails.cache.read('check:migrate:adjust_report_design_schema:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team_languages = team&.get_languages || ['en']
        report_language = team_languages.length == 1 ? team_languages.first : 'und'
        team.project_medias.find_in_batches(:batch_size => 1000) do |pms|
          ids = pms.map(&:id)
          items = []
          Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: ids).find_each do |report|
            data = report.data.with_indifferent_access
            unless data.blank?
              puts "[#{Time.now}] Updating report with ID #{report.id}..."
              options = data[:options] ? [data[:options]].flatten : []
              data[:options] = options.length > 0 ? options.shift : {}
              selected_option = nil
              if options.length > 0 && data[:options][:title].blank? && data[:options][:text].blank?
                selected_option = options.find{|e| !e[:title].blank? || !e[:text].blank? }
              end
              data[:options] = selected_option unless selected_option.nil?
              # set report language
              data[:options][:language] = report_language
              report.data = data
              items << report
            end
          end
          # Import items with existing ids to make update
          Dynamic.import(items, recursive: false, validate: false, on_duplicate_key_update: [:data])
        end
        # Update fact check to sync report language
        FactCheck.joins(:claim_description)
        .joins("INNER JOIN project_medias pm ON pm.id = claim_descriptions.project_media_id")
        .where('pm.team_id = ?', team.id).update_all(language: report_language)
        Rails.cache.write('check:migrate:adjust_report_design_schema:team_id', team.id)
      end
      RequestStore.store[:skip_rules] = false
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
