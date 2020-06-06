module PenderData

  attr_accessor :pender_error, :pender_error_code, :pender_key

  def validate_pender_result(force = false, retry_on_error = false)
    if !self.url.blank? && !self.skip_pender
      params = { url: self.url }
      params[:refresh] = '1' if force
      result = { type: 'error', data: { code: -1 } }.with_indifferent_access
      pender_key = get_pender_key
      begin
        result = PenderClient::Request.get_medias(CONFIG['pender_url_private'], params, pender_key)
      rescue StandardError => e
        Rails.logger.error("[Pender] Exception for URL #{self.url}: #{e.message}")
        Airbrake.notify(e, params: params) if Airbrake.configured?
      end
      if result['type'] == 'error'
        self.pender_error = true
        self.pender_error_code = result['data']['code']
        self.retry_pender_or_fail(force, retry_on_error, result)
      else
        self.pender_data = result['data'].merge(pender_key: pender_key)
        # set url with normalized pender URL
        self.url = begin result['data']['url'] rescue self.url end
      end
    end
  end

  def retry_pender_or_fail(force, retry_on_error, result)
    (!force && retry_on_error) ? validate_pender_result(true) : errors.add(:base, self.handle_pender_error(result['data']['code']))
  end

  def handle_pender_error(code)
    case code.to_i
    when PenderClient::ErrorCodes::DUPLICATED
      I18n.t('errors.messages.pender_conflict')
    when PenderClient::ErrorCodes::INVALID_VALUE
      I18n.t('errors.messages.pender_url_invalid')
    when PenderClient::ErrorCodes::UNSAFE
      I18n.t('errors.messages.pender_url_unsafe')
    else
      I18n.t('errors.messages.pender_could_not_parse')
    end
  end

  def set_pender_result_as_annotation
    unless self.pender_data.nil?
      data = self.pender_data.except(:pender_key)
      m = self.metadata_annotation
      current_data = begin JSON.parse(m.get_field_value('metadata_value')) rescue {} end
      current_data['refreshes_count'] ||= 0
      current_data['refreshes_count'] += 1
      data['refreshes_count'] = current_data['refreshes_count']
      m.set_fields = { metadata_value: data.to_json }.to_json
      m.save!
    end
  end

  def metadata_annotation
    pender = BotUser.where(name: 'Pender').last
    m = Dynamic.where(annotation_type: 'metadata', annotated_type: self.class_name, annotated_id: self.id).first
    if m.nil?
      m = Dynamic.new
      m.annotation_type = 'metadata'
      m.annotated = self
      m.annotator = pender unless pender.nil?
    end
    m
  end

  def skip_pender
    @skip_pender
  end

  def skip_pender=(bool)
    @skip_pender = bool
  end

  def pender_data
    @pender_data
  end

  def pender_data=(data)
    @pender_data = data
  end

  def refresh_pender_data
    self.validate_pender_result(true)
    self.set_pender_result_as_annotation
  end

  def get_pender_key
    self.pender_key || CONFIG['pender_key']
  end
end
