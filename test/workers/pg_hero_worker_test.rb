require_relative '../test_helper'

class PgHeroWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
  end

  test "should create another job when job runs" do
    PgHero.stubs(:capture_query_stats).once
    Sidekiq::Testing.fake!
    PgHeroWorker.drain
    assert_equal 0, PgHeroWorker.jobs.size
    PgHeroWorker.perform_in(5.minutes)
    assert_equal 1, PgHeroWorker.jobs.size
    
    Sidekiq::Testing.inline!
    PgHeroWorker.stubs(:perform_in).once
    PgHeroWorker.perform_async
  end
end
