class TiplineStatisticsPeriodicCheckWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    # adding a buffer of one hour to our expected 24 hours interval
    periodic_check = Time.now.ago(25.hours)
    count = MonthlyTeamStatistic.where('created_at > ? OR updated_at > ?', periodic_check, periodic_check).count
    CheckSentry.notify(StandardError.new('No MonthlyTeamStatistic updated or created in the last 24 hours')) if count == 0
  end
end
