class Bot::Keep
  def self.send_to_keep_in_background(url, token, annotation_id)
    Bot::Keep.delay_for(1.second).send_to_keep({ url: url, token: token }, annotation_id)
  end

  def self.send_to_keep(params, annotation_id)
    uri = URI('https://www.bravenewtech.org/api/')

    response = Net::HTTP.post_form(uri, params)

    data = JSON.parse(response.body)
    data['timestamp'] = Time.now.to_i

    annotation = Dynamic.find(annotation_id)
    annotation.set_fields = { keep_backup_response: data.to_json }.to_json
    annotation.save!

    # If not finished (error or success), run again
    if !data.has_key?('location') && data['status'].to_i != 418 && data.has_key?('package')
      # Bot::Keep.delay_for(5.minutes).send_to_keep({ package: data['package'], token: params[:token] }, annotation_id)
      Bot::Keep.delay_for(5.minutes).is_archived?(data['package'], annotation_id)
    end
  end

  def self.is_archived?(package, annotation_id)
    uri = URI("https://www.bravenewtech.org/review.php?p=#{package}")
    response = Net::HTTP.get_response(uri)
    annotation = Dynamic.find(annotation_id)
    data = { timestamp: Time.now.to_i, package: package }
    if response.body =~ /SHA1 hash: [a-z0-9]+/
      data[:location] = uri.to_s
    else
      data[:status] = 'Processing'
      Bot::Keep.delay_for(5.minutes).is_archived?(package, annotation_id)
    end
    annotation.set_fields = { keep_backup_response: data.to_json }.to_json
    annotation.save!
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
      ts.save!
      ts
    end

    private

    def send_to_keep
      token = self.get_keep_token
      if !token.blank? && self.media.is_a?(Link)
        annotation = self.create_keep_annotation
        Bot::Keep.send_to_keep_in_background(self.url, token, annotation.id)
      end
    end
  end
end
