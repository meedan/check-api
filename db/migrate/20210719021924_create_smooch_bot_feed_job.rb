class CreateSmoochBotFeedJob < ActiveRecord::Migration
  def change
    # To ensure that the job will be scheduled and not run right away
    Sidekiq::Testing.fake!

    Bot::Smooch.delay_for(15.minutes, retry: 0).refresh_rss_feeds_cache unless Rails.env.test?
  end
end
