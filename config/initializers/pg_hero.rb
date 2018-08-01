# Start scheduler to save queries information every 5 minutes
ENV['PGHERO_USERNAME'] = nil
ENV['PGHERO_PASSWORD'] = nil
count = Sidekiq::ScheduledSet.new.map(&:klass).select{ |klass| klass == 'PgHeroWorker' }.size
PgHeroWorker.perform_in(5.minutes) if count == 0
