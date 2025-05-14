class TiplineStatisticsPeriodicCheckWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    periodic_check = Time.now.ago(26.hours)
    count = MonthlyTeamStatistic.where('created_at > ? OR updated_at > ?', periodic_check, periodic_check).count
    CheckSentry.notify(StandardError.new('No MonthlyTeamStatistic updated or created in the last 24 hours')) if count == 0
  end
end
