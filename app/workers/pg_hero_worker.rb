class PgHeroWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :pg_hero, :retry => false

  def perform(model, options, type)
    PgHero.capture_query_stats
    PgHeroWorker.perform_in(5.minutes)
  end
end
