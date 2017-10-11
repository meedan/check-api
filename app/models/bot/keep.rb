class Bot::Keep
  def self.send_to_keep_in_background(url, token, annotation_id)
    Bot::Keep.delay_for(1.second).send_to_keep({ url: url, token: token }, annotation_id)
  end

  def self.send_to_keep(params, annotation_id, endpoint = '')
    uri = URI("https://www.bravenewtech.org/api/#{endpoint}")

    response = Net::HTTP.post_form(uri, params)

    data = JSON.parse(response.body)
    data['timestamp'] = Time.now.to_i

    annotation = Dynamic.find(annotation_id)
    annotation.set_fields = { keep_backup_response: data.to_json }.to_json
    annotation.disable_es_callbacks = Rails.env.to_s == 'test'
    annotation.save!

    # If not finished (error or success), run again
    if !data.has_key?('location') && data['status'].to_i != 418 && data.has_key?('package')
      Bot::Keep.delay_for(3.minutes).send_to_keep({ package: data['package'], token: params[:token] }, annotation_id, 'status.php')
    else
      ::Pusher.trigger([annotation.annotated.media.pusher_channel], 'media_updated', { message: data.to_json }) unless CONFIG['pusher_key'].blank?
    end
  end

  ProjectMedia.class_eval do
    after_create :send_to_keep

    def get_keep_token
      self.project.team.get_keep_enabled.to_i == 1 ? CONFIG['keep_token'] : nil
    end

    def create_keep_annotation
      ts = Dynamic.new
      ts.skip_check_ability = true
      ts.annotation_type = 'keep_backup'
      ts.annotated = self
      ts.set_fields = { keep_backup_response: '{}' }.to_json
      ts.disable_es_callbacks = Rails.env.to_s == 'test'
      ts.save!
      ts
    end

    def update_keep=(_update)
      user_current = User.current
      User.current = nil
      annotation = self.annotations.where(annotation_type: 'keep_backup').last.load
      annotation.disable_es_callbacks = Rails.env.to_s == 'test'
      annotation.set_fields = { keep_backup_response: '{}' }.to_json
      annotation.save!
      User.current = user_current
      Bot::Keep.send_to_keep_in_background(self.media.url, self.get_keep_token, annotation.id)
    end

    private

    def send_to_keep
      token = self.get_keep_token
      if !token.blank? && self.media.is_a?(Link)
        annotation = self.create_keep_annotation
        Bot::Keep.send_to_keep_in_background(self.media.url, token, annotation.id)
      end
    end
  end
end
