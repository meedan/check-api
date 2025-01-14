# rake check:migrate:add_blank_media_to_standalone_fact_checks
namespace :check do
  namespace :migrate do
    task add_blank_media_to_standalone_fact_checks: :environment do
      started = Time.now.to_i
      query = FactCheck.joins(:claim_description).where(imported: false).where('claim_descriptions.project_media_id' => nil)
      n = query.count
      i = 0
      query.find_each do |fact_check|
        i += 1
        claim = fact_check.claim_description
        claim.enable_create_blank_media = true
        claim.send(:create_blank_media_if_needed)
        claim.save!
        puts "[#{Time.now}] [#{i}/#{n}] Added blank media to claim ##{claim.id}"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Number of standalone fact-checks without blank media: #{query.count}"
    end
  end
end
