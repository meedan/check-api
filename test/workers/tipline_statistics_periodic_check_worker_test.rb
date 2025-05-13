require_relative '../test_helper'

class TiplineStatisticsPeriodicCheckWorkerTest < ActiveSupport::TestCase
  test "should notify Sentry for missing tipline statistics updates in last 24 hours" do
    t = create_team
    # Verify both created/updated dates
    Time.stubs(:now).returns(Time.new - 3.days)
    ms = create_monthly_team_statistic team: t
    Time.unstub(:now)
    CheckSentry.expects(:notify).once
    TiplineStatisticsPeriodicCheckWorker.new.perform
    # Verify config option
    stub_configs({ 'ENABLE_TIPLINE_STATS_MONITORING' => false }) do
      CheckSentry.expects(:notify).never
      TiplineStatisticsPeriodicCheckWorker.new.perform
    end
    # Verify updated date
    ms.updated_at = Time.now
    ms.save!
    CheckSentry.expects(:notify).never
    TiplineStatisticsPeriodicCheckWorker.new.perform
    ms.destroy
    CheckSentry.expects(:notify).once
    TiplineStatisticsPeriodicCheckWorker.new.perform
    # Verify both created/updated dates
    create_monthly_team_statistic team: t
    CheckSentry.expects(:notify).never
    TiplineStatisticsPeriodicCheckWorker.new.perform
  end
end
