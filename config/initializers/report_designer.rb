Dynamic.class_eval do
  before_validation do
    self.keep_file = true if self.annotation_type == 'report_design'
  end

  after_save do
    if self.annotation_type == 'report_design'
      action = self.action
      self.copy_report_image_paths if action == 'save' || action =~ /publish/
      if action =~ /publish/
        ReportDesignerWorker.perform_in(1.second, self.id, action)
      end
    end

    title = nil
    summary = nil
    url = nil
    pm = self.annotated
    if self.annotation_type == 'report_design' && (self.action == 'save' || self.action =~ /publish/) && pm&.claim_description
      fc = pm.claim_description.fact_check
      user = self.annotator || User.current
      url = self.report_design_field_value('published_article_url')
      language = self.report_design_field_value('language')
      state = self.data['state']
      publisher_id =  state == 'published' ? self.annotator_id : nil
      fields = {
        user: user,
        skip_report_update: true,
        url: url,
        language: language,
        publisher_id: publisher_id,
        report_status: state,
        rating: pm.status
      }
      if self.report_design_field_value('use_text_message')
        title = self.report_design_field_value('title')
        summary = self.report_design_field_value('text')
        fields.merge!({
          title: title,
          summary: summary,
        })
      elsif self.report_design_field_value('use_visual_card')
        title = self.report_design_field_value('headline')
        summary = self.report_design_field_value('description')
        fields.merge!({
          title: title,
          summary: summary,
        })
      end
      if fc.nil?
        FactCheck.create({ claim_description: pm.claim_description }.merge(fields))
      else
        PaperTrail.request(enabled: false) do
          fields.each { |field, value| fc.send("#{field}=", value) }
          fc.skip_check_ability = true
          fc.save!
        end
      end
    end

    if self.annotation_type == 'report_design' && self.action =~ /publish/
      # Wait for 1 minute to be sure that the item is indexed in the feed
      Feed.delay_for(1.minute, retry: 0).notify_subscribers(pm, title, summary, url)
      Request.delay_for(1.minute, retry: 0).update_fact_checked_by(pm)
    end

    if self.annotation_type == 'report_design' && self.action =~ /pause/
      # Update report fields
      fc = pm&.claim_description&.fact_check
      unless fc.nil?
        PaperTrail.request(enabled: false) do
          state = self.data['state']
          fields = {
            skip_report_update: true,
            publisher_id: nil,
            report_status: state,
            rating: pm.status
          }
          fields.each { |field, value| fc.send("#{field}=", value) }
          fc.skip_check_ability = true
          fc.save!
        end
      end
    end
  end

  def report_design_introduction(data, language)
    if self.annotation_type == 'report_design'
      introduction = self.report_design_field_value('introduction').to_s
      introduction = introduction.gsub('{{status}}', self.annotated&.status_i18n(nil, { locale: language }))
      introduction = introduction.gsub('{{query_date}}', self.report_design_date(Time.at(data['received']).to_date, language)) if data['received']
      introduction
    end
  end

  def report_design_team_setting_value(field, language)
    self.annotated&.team&.get_report.to_h.with_indifferent_access.dig(language, field) if self.annotation_type == 'report_design'
  end

  def report_design_to_tipline_search_result
    if self.annotation_type == 'report_design'
      TiplineSearchResult.new(
        id: self.id,
        type: :fact_check,
        team: self.annotated.team,
        title: self.report_design_field_value('title'),
        body: self.report_design_field_value('text'),
        image_url: self.report_design_image_url,
        language: self.report_design_field_value('language'),
        url: self.report_design_field_value('published_article_url'),
        format: (!self.report_design_field_value('use_text_message') && self.report_design_field_value('use_visual_card')) ? :image : :text
      )
    end
  end

  def report_design_text(language = nil, hide_body = false)
    if self.annotation_type == 'report_design'
      self.report_design_to_tipline_search_result.text(language, hide_body)
    end
  end

  def report_design_field_value(field)
    return nil unless self.annotation_type == 'report_design'
    data = self.data.with_indifferent_access
    data[:options].blank? ? nil : data[:options][field]
  end

  def report_design_image_url
    self.annotation_type == 'report_design' ? Dynamic.find(self.id).report_design_field_value('visual_card_url') : nil
  end

  def adjust_report_design_image_url(url)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    (ENV['RAILS_ENV'] == 'development' && url =~ /^#{CheckConfig.get('storage_asset_host')}/) ? url.gsub(CheckConfig.get('storage_asset_host'), "#{CheckConfig.get('storage_endpoint')}/#{CheckConfig.get('storage_bucket')}") : url
  end

  def report_design_date(date, language)
    I18n.l(date, locale: language.to_s.tr('_', '-'), format: :long)
  end

  def report_design_placeholders(language)
    facebook = self.report_design_team_setting_value('facebook', language)
    twitter = self.report_design_team_setting_value('twitter', language)
    telegram = self.report_design_team_setting_value('telegram', language)
    instagram = self.report_design_team_setting_value('instagram', language)
    {
      title: self.report_design_field_value('headline'),
      status: self.report_design_field_value('status_label'),
      description: self.report_design_field_value('description'),
      url: self.report_design_field_value('url'),
      whatsapp: self.report_design_team_setting_value('whatsapp', language),
      facebook: facebook.blank? ? nil : "m.me/#{facebook}",
      twitter: twitter.blank? ? nil : "@#{twitter}",
      telegram: telegram.blank? ? nil : "t.me/#{telegram}",
      instagram: instagram.blank? ? nil : "instagram.com/#{instagram}",
      viber: self.report_design_team_setting_value('viber', language),
      line: self.report_design_team_setting_value('line', language)
    }
  end

  def report_image_generate_png
    if self.annotation_type == 'report_design'
      team = self.annotated&.team
      data = self.data.with_indifferent_access
      language = data[:options][:language]

      # Get the template and generate the HTML
      FileUtils.mkdir_p(File.join(Rails.root, 'public', 'report_design'))
      template = team.get_report_design_image_template
      doc = Nokogiri::HTML(template)
      body = doc.at_css('body')
      overlay = self.report_design_field_value('dark_overlay') ? 'dark' : 'light'
      body['class'] = ['report', language.to_s, overlay].join(' ')
      html = doc.at_css('html')
      html['lang'] = language.to_s
      self.report_design_placeholders(language).each do |key, value|
        el = doc.at_css('#' + key.to_s)
        value.blank? ? el.remove : el.add_child(value)
      end
      date = self.report_design_field_value('date')
      doc.at_css('#date').content = date || self.report_design_date(self.updated_at.to_date, language)
      avatar = self.adjust_report_design_image_url(team.avatar)
      image = self.adjust_report_design_image_url(self.report_design_field_value('image'))
      temp_name = 'temp-' + self.id.to_s + '-' + language + '.html'
      temp = File.join(Rails.root, 'public', 'report_design', temp_name)
      output = File.open(temp, 'w+')
      output.puts doc.to_s.gsub(/#CCCCCC/, self.report_design_field_value('theme_color').to_s).gsub('%IMAGE_URL%', image.to_s).gsub('%AVATAR_URL%', avatar.to_s)
      output.close

      # Upload the HTML to S3
      path = "report_design/#{temp_name}"
      CheckS3.write(path, 'text/html', File.read(temp))
      temp_url = CheckS3.public_url(path)

      # Convert the HTML to PNG
      uri = URI("#{CheckConfig.get('narcissus_url')}/?url=#{temp_url}&selector=%23frame")
      request = Net::HTTP::Get.new(uri)
      request['x-api-key'] = CheckConfig.get('narcissus_token')
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
      screenshot = JSON.parse(response.body)['url']
      raise "Unexpected response from screenshot service for request #{uri}: #{response.body}" unless screenshot =~ /^http/
      data[:options][:visual_card_url] = screenshot
      self.set_fields = data.to_json
      self.save!
      FileUtils.rm_f temp
      CheckS3.delete(path)
    end
  end

  def copy_report_image_paths
    return unless self.saved_change_to_file?
    fields = self.set_fields || '{}'
    data = { 'options' => {} }.merge(JSON.parse(fields))
    image = self.file.first
    unless image.nil?
      url = begin image.file.public_url rescue nil end
      data['options']['image'] = url unless url.nil?
    end
    self.set_fields = data.to_json
    self.action = nil
    self.save!
  end

  def sent_count
    if self.annotation_type == 'report_design'
      pmids = self.annotated.related_items_ids
      TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: pmids).where.not(smooch_report_received_at: 0).count
    end
  end

  def should_send_report_in_this_language?(language)
    self.annotation_type == 'report_design' && self.report_design_to_tipline_search_result.should_send_in_language?(language)
  end
end
