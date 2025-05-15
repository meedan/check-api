require_relative '../test_helper'

class TiplineStatisticsPeriodicCheckWorkerTest < ActiveSupport::TestCase
  test "should notify Sentry for missing tipline statistics updates in last 24 hours" do
    t = create_team
    # Verify both created/updated dates
    ms = nil
    travel_to 3.days.ago do
      ms = create_monthly_team_statistic team: t
    end
    CheckSentry.expects(:notify).once
    TiplineStatisticsPeriodicCheckWorker.new.perform
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
