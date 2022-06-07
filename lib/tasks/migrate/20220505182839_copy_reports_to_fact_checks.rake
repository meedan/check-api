namespace :check do
  namespace :migrate do
    task reports_to_fact_checks: :environment do
      started = Time.now.to_i
      n = 0
      join = 'INNER JOIN project_medias pm ON pm.id = annotations.annotated_id'
      Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia').joins(join).where('pm.user_id != ?', BotUser.fetch_user.id).find_each do |report|
        if report.get_field_value('state') == 'published'
          pm = report.annotated
          next if pm.nil?
          begin
            if pm.claim_description.nil? || pm.claim_description.fact_check.nil?
              user = report.annotator || Version.from_partition(pm.team_id).where(item_id: report.id.to_s, item_type: ['Annotation', 'Dynamic']).first&.user || BotUser.fetch_user
              cd = pm.claim_description || ClaimDescription.create!(project_media: pm, description: '​', user: user)
              fields = { user: user, skip_report_update: true }
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
            end
          rescue Exception => e
            puts "[#{Time.now}] Could not create fact-check for report #{report.id}: #{e.message}"
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
