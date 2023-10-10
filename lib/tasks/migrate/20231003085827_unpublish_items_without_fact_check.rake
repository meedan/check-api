namespace :check do
  namespace :migrate do
    task export_published_items_without_fact_check: :environment do
      started = Time.now.to_i
      log_items = []
      data_csv = []
      Team.find_each do |team|
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
            total += diff.length
            ProjectMedia.where(id: diff).find_each do |pm|
              data_csv << [team.name, pm.full_url, pm.media_published_at]
            end
          end
        end
        log_items << { team_slug: team.slug, total: total } unless total == 0
      end
      unless data_csv.empty?
        # Export items to CSV
        require 'csv'
        file = "#{Rails.root}/public/list_published_reports_without_fact_check_#{Time.now.to_i}.csv"
        headers = ["Workspace", "URL", "Published at"]
        CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
          data_csv.each do |d|
            writer << d
          end
        end
        puts "\nExported items to file:: #{file}"
      end
      puts "Logs data:: #{log_items.inspect}" if log_items.length > 0
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # Copy reports to fact check and used `check:migrate:reports_to_fact_checks` rake task as a reference
    task set_fact_check_for_published_items: :environment do
      started = Time.now.to_i
      n = 0
      last_team_id = Rails.cache.read('check:migrate:set_fact_check_for_published_items:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        print '.'
        languages = team.get_languages || ['en']
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
            Dynamic.where(annotation_type: "report_design", annotated_type: "ProjectMedia", annotated_id: diff).find_each do |report|
              pm = report.annotated
              begin
                user_id = report.annotator_id
                cd = pm.claim_description || ClaimDescription.create!(project_media: pm, description: '​', user_id: user_id)
                language = report.report_design_field_value('language')
                fc_language = languages.include?(language) ? language : 'und'
                fields = { user_id: user_id, skip_report_update: true, language: fc_language }
                if report.report_design_field_value('use_text_message')
                  fields.merge!({
                    title: report.report_design_field_value('title'),
                    summary: report.report_design_field_value('text'),
                    url: report.report_design_field_value('published_article_url')
                  })
                elsif report.report_design_field_value('use_visual_card')
                  fields.merge!({
                    title: report.report_design_field_value('headline'),
                    summary: report.report_design_field_value('description'),
                    url: report.report_design_field_value('published_article_url')
                  })
                end
                fc = FactCheck.create!({ claim_description: cd }.merge(fields))
                n += 1
                puts "[#{Time.now}] #{n}. Created fact-check #{fc.id}"
              rescue Exception => e
                puts "[#{Time.now}] Could not create fact-check for report #{report.id}: #{e.message}"
              end
            end
          end
        end
        Rails.cache.write('check:migrate:set_fact_check_for_published_items:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end