class Bot::Facebook < ActiveRecord::Base
  include Bot::SocialBot
  
  def self.default
    Bot::Facebook.where(name: 'Facebook Bot').last
  end

  def send_to_facebook_in_background(annotation)
    self.send_to_social_network_in_background(:send_to_facebook, annotation)
  end

  def self.send_to_facebook(annotation_id)
    translation = Dynamic.where(id: annotation_id, annotation_type: 'translation').last
    Bot::Facebook.default.send_to_facebook(translation)
  end

  def send_to_facebook(translation)
    send_to_social_network 'facebook', translation do
      # Ask Bridge Reader to generate the screenshot for Facebook
      # Screenshots currently disabled
      # ---
      # screenshot_uri = nil
      # begin
      #   screenshot_uri = URI(self.embed_url(:private, :png))
      #   Net::HTTP.get(screenshot_uri)
      # rescue
      #   Rails.logger.info('Could not request screenshot: ' + screenshot_uri.to_s)
      # end
      # ---

      # Auto-publishing is currently not working: https://developers.facebook.com/docs/graph-api/reference/v3.1/user/feed#publish
      # ---
      # auth = self.get_auth('facebook')
      # uri = URI('https://graph.facebook.com/me/feed')
      # data = {
      #   message: self.text,
      #   link: self.embed_url,
      #   access_token: auth['token']
      # }
      # 
      # response = Net::HTTP.post_form(uri, data)
      # 'https://facebook.com/' + JSON.parse(response.body)['id'].to_s
      # ---
      # For now, our solution is to show a link to share it manually
      
      url = self.embed_url
      description = self.text
      "javascript:window.open('https://www.facebook.com/sharer.php?u=#{url}&description=#{description}', 'Share', 'width=600, height=600');"
    end
  end
end
