class Bot::Facebook < ActiveRecord::Base
  include Bot::SocialBot
  
  def self.default
    Bot::Facebook.where(name: 'Facebook Bot').last
  end

  def send_to_facebook_in_background(annotation)
    Bot::Facebook.delay_for(1.second).send_to_facebook(annotation.id) if !annotation.nil? && annotation.annotation_type == 'translation'
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
        access_token: auth['token']
      }
      # data.merge!({ link: self.embed_url })
      response = Net::HTTP.post_form(uri, data)
      JSON.parse(response.body)['id']
    end
  end
end
