namespace :check do
  namespace :migrate do
    task update_fact_check_cached_fields: :environment do
      FIELDS = ['fact_check_title', 'fact_check_summary', 'fact_check_url']
      started = Time.now.to_i
      query = ProjectMedia.joins(claim_description: :fact_check)
      count = query.count
      counter = 0
      query.find_each do |pm|
        counter += 1
        failed = false
        begin
          FIELDS.each { |field| pm.send(field) } # Just cache if it's not cached yet
        rescue Exception => e
          failed = e.message
        end
        puts "[#{Time.now}] Processed item #{counter}/#{count}: ##{pm.id} (#{failed ? 'failed with ' + e.message : 'success'})"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
