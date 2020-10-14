class CreateSmoochBotFeedJob < ActiveRecord::Migration
  def change
    Bot::Smooch.delay_for(15.minutes, retry: 0).refresh_rss_feeds_cache unless Rails.env.test?
  end
end
