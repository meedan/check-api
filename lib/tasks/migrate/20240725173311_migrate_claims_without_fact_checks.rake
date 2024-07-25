namespace :check do
  namespace :migrate do
    task migrate_claims_without_fact_checks: :environment do
      started = Time.now.to_i
      last_cd_id = Rails.cache.read('check:migrate:migrate_claims_without_fact_checks:claim_description_id') || 0
      ClaimDescription.where('claim_descriptions.id > ?', last_cd_id).joins("LEFT JOIN fact_checks fc ON claim_descriptions.id = fc.claim_description_id")
      .where('fc.id IS NULL').find_in_batches(batch_size: 2500) do |cds|
        print '.'
        fc_items = []
        cds.each do |cd|
          fc_items << { claim_description_id: cd.id, user_id: cd.user_id, created_at: cd.created_at, updated_at: cd.updated_at }
        end
        FactCheck.insert_all(fc_items)
        max_id = cds.map(&:id).max
        Rails.cache.write('check:migrate:migrate_claims_without_fact_checks:claim_description_id', max_id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
