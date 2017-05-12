class Bot::Twitter < ActiveRecord::Base
  include Bot::SocialBot

  attr_accessor :twitter_client

  def self.default
    Bot::Twitter.where(name: 'Twitter Bot').last
  end

  def send_to_twitter_in_background(annotation)
    Bot::Twitter.delay_for(1.second).send_to_twitter(annotation.id) if !annotation.nil? && annotation.annotation_type == 'translation'
  end

  def self.send_to_twitter(annotation_id)
    translation = Dynamic.where(id: annotation_id, annotation_type: 'translation').last
    Bot::Twitter.default.send_to_twitter(translation)
  end

  def send_to_twitter(translation)
    send_to_social_network 'twitter', translation do
      auth = self.get_auth('twitter')

      self.twitter_client = Twitter::REST::Client.new do |config|
        config.consumer_key        = CONFIG['twitter_consumer_key']
        config.consumer_secret     = CONFIG['twitter_consumer_secret']
        config.access_token        = auth['token']
        config.access_token_secret = auth['secret']
      end

      text = self.format_for_twitter(self.text)
      tweet = self.twitter_client.update(text)
      tweet.id
    end

    # Waiting for Check integration with Bridge Reader
    # image = self.get_screenshot_for_twitter
    # tweet = client.update_with_media(text, File.new(image))
    # FileUtils.rm(image)
  end

  protected

  # def embed_url
  #   # Return URL for this translation on Bridge Reader
  #   ''
  # end

  # def twitter_url_size
  #   Rails.cache.fetch('twitter_short_url_length', expire_in: 24.hours) do
  #     self.twitter_client.configuration.short_url_length_https + 1
  #   end
  # end

  def format_for_twitter(text)
    size = 140
    text.truncate(size)
    # url = self.embed_url
    # size = 140 - self.twitter_url_size * 2 # one URL for Bridge Reader and another one for the attached image
    # self.text.truncate(size) + ' ' + url
  end
end
