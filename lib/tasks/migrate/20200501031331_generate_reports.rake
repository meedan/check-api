namespace :check do
  namespace :migrate do
    task generate_reports: :environment do
      last_id = Rails.cache.read('check:migrate:generate_reports:last_id')
      raise "No last_id found in cache for check:migrate:generate_reports! Aborting." if last_id.nil?
      i = 0
      skipped = 0
      total = 0
      started = Time.now.to_i
      n = Dynamic.where(annotation_type: 'analysis').where('id <= ?', last_id).count
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_clear_cache] = true
      Dynamic.where(annotation_type: 'analysis').where('id <= ?', last_id).find_each do |a|
        begin
          i += 1
          pm = a.annotated
          if pm.is_finished?
            analysis = begin a.get_field_value('analysis_text').to_s rescue '' end
            if !analysis.blank?
              report = Dynamic.new
              report.annotated = pm
              report.annotation_type = 'report_design'
              report.set_fields = {
                state: 'published',
                use_text_message: true,
                text: analysis
              }.to_json
              report.save!
              total += 1
              puts "#{i}/#{n}) [#{Time.now}] Report generated for project media #{pm.id}"
            else
              puts "#{i}/#{n}) [#{Time.now}] No report generated because analysis is blank"
            end
          else
            puts "#{i}/#{n}) [#{Time.now}] No report generated because status is not final"
          end
        rescue Exception => e
          msg = e.message || 'unknown'
          skipped += 1
          puts "#{i}/#{n}) [#{Time.now}] Skipping (because of error #{msg})"
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done. #{total} reports generated and #{skipped} failed in #{minutes} minutes."
      Rails.cache.delete('check:migrate:generate_reports:last_id')
      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_clear_cache] = false
    end
  end
end
