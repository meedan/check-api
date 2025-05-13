class TiplineStatisticsPeriodicCheckWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    if CheckConfig.get('ENABLE_TIPLINE_STATS_MONITORING', true)
      periodic_check = Time.now.ago(1.day)
      count = MonthlyTeamStatistic.where('created_at > ? OR updated_at > ?', periodic_check, periodic_check).count
      CheckSentry.notify(StandardError.new('No MonthlyTeamStatistic updated or created in the last 24 hours')) if count == 0
    end
  end
end
