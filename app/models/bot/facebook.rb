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
      auth = self.get_auth('facebook')
      uri = URI('https://graph.facebook.com/me/feed')
      data = {
        message: self.text,
        link: self.embed_url,
        access_token: auth['token']
      }
      # data.merge!({ link: self.embed_url })
      response = Net::HTTP.post_form(uri, data)
      'https://facebook.com/' + JSON.parse(response.body)['id'].to_s
    end
  end
end
