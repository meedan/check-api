module PenderData
  def validate_pender_result(force = false)
    if !self.url.blank? && !self.skip_pender
      params = { url: self.url }
      params[:refresh] = '1' if force
      result = PenderClient::Request.get_medias(CONFIG['pender_host'], params, CONFIG['pender_key'])
      if (result['type'] == 'error')
        errors.add :base, self.handle_pender_error(result['data']['code'])
      else
        self.pender_data = result['data']
        # set url with normalized pender URL
        self.url = result['data']['url']
      end
    end
  end

  def handle_pender_error(code)
    case code.to_i
    when 9
      I18n.t(:pender_conflict, default: 'This link is already being parsed, please try again in a few seconds.')
    else
      I18n.t(:pender_could_not_parse, default: 'Could not parse this media')
    end
  end

  def set_pender_result_as_annotation
    unless self.pender_data.nil?
      data = self.pender_data
      em = self.pender_embed
      self.overridden_embed_attributes.each{ |k| em.data[k.to_s] = data[k.to_s] } if self.respond_to?('overridden_embed_attributes')
      em.published_at = data['published_at'].to_time.to_i unless data['published_at'].nil?
      em.refreshes_count ||= 0
      em.refreshes_count += 1
      data['refreshes_count'] = em.refreshes_count
      em.embed = data.to_json
      em.save!
    end
  end

  def pender_embed
    pender = Bot::Bot.where(name: 'Pender').last
    em = Embed.where(annotation_type: 'embed', annotated_type: self.class_name, annotated_id: self.id).first
    if em.nil?
      em = Embed.new
      em.annotated = self
      em.annotator = pender unless pender.nil?
    end
    em
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
end
