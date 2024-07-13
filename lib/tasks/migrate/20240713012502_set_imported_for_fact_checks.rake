namespace :check do
  namespace :migrate do
    task set_imported_for_fact_checks: :environment do
      puts "[#{Time.now}] Setting imported field for existing fact-checks"
      started = Time.now.to_i
      BATCH_SIZE = 7
      query = FactCheck.joins(:user).where('users.type' => 'BotUser').where(imported: false)
      count = query.count
      total = 0
      while count > 0
        puts "[#{Time.now}] Updating maximum #{BATCH_SIZE} fact-checks, out of #{count}"
        query.limit(BATCH_SIZE).update_all(imported: true)
        total += (BATCH_SIZE < count ? BATCH_SIZE : count)
        count = query.count
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Updated #{total} fact-checks."
    end
  end
end
