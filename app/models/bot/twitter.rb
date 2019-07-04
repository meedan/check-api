class Bot::Twitter < BotUser
  
  check_settings
  
  include Bot::SocialBot

  attr_accessor :twitter_client

  def self.default
    Bot::Twitter.new
  end

  def send_to_twitter_in_background(annotation)
    self.send_to_social_network_in_background(:send_to_twitter, annotation)
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

      tweet.url.to_s
    end
  end

  protected

  # Not sending any screenshot for now
  # def get_screenshot_for_twitter
  #   require 'open-uri'
  #   url = self.embed_url(:private, :png)
  #   path = File.join(Dir::tmpdir, "#{Time.now.to_i}_#{rand(100000)}.png")
  #   # Try to get screenshot from Reader... if it doesn't work, use a default image
  #   begin
  #     IO.copy_stream(open(url, { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE, read_timeout: 60 }), path)
  #   rescue
  #     FileUtils.cp File.join(Rails.root, 'public', 'images', 'bridge.png'), path
  #   end
  #   path
  # end

  def twitter_url_size
    Rails.cache.fetch('twitter_short_url_length', expire_in: 24.hours) do
      self.twitter_client.configuration.short_url_length_https + 1
    end
  end

  def format_for_twitter(text)
    url = self.embed_url
    size = 280 - self.twitter_url_size
    text.truncate(size) + ' ' + url.to_s
  end
end
