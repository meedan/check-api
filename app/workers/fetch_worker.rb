class FetchWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'fetch', retry: 3

  sidekiq_retry_in { |_count, _exception| 300 } # Retry 5 minutes later in order to avoid database conflicts like ActiveRecord::PreparedStatementCacheExpired

  def perform(claim_review, team_id, user_id, status_fallback, status_mapping, auto_publish_reports)
    Bot::Fetch::Import.import_claim_review(claim_review, team_id, user_id, status_fallback, status_mapping, auto_publish_reports)
  end
end
