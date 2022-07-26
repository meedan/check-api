Dynamic.class_eval do
  before_validation do
    self.keep_file = true if self.annotation_type == 'report_design'
  end

  after_save do
    if self.annotation_type == 'report_design' && (self.action == 'save' || self.action =~ /publish/)
      Bot::Alegre.delay_for(1.second, retry: 3).update_context(self.annotated.id, {published: self.report_design_field_value('state') == 'published'})
      if self.annotated&.claim_description
        fc = self.annotated.claim_description.fact_check
        user = self.annotator || User.current
        fields = { user: user, skip_report_update: true }
        if self.report_design_field_value('use_text_message')
          fields.merge!({
            title: self.report_design_field_value('title'),
            summary: self.report_design_field_value('text'),
            url: self.report_design_field_value('published_article_url')
          })
        elsif self.report_design_field_value('use_visual_card')
          fields.merge!({
            title: self.report_design_field_value('headline'),
            summary: self.report_design_field_value('description'),
            url: self.report_design_field_value('published_article_url')
          })
        end
        if fc.nil?
          FactCheck.create({ claim_description: self.annotated.claim_description }.merge(fields))
        else
          fields.each { |field, value| fc.send("#{field}=", value) }
          fc.save
        end
      end
    end
  end

  def report_design_introduction(data, language)
    if self.annotation_type == 'report_design'
      introduction = self.report_design_field_value('introduction', language).to_s
      introduction = introduction.gsub('{{status}}', self.report_design_field_value('status_label', language).to_s)
      introduction = introduction.gsub('{{query_date}}', self.report_design_date(Time.at(data['received']).to_date, language)) if data['received']
      introduction
    end
  end

  def report_design_team_setting_value(field, language)
    self.annotated&.team&.get_report.to_h.with_indifferent_access.dig(language, field) if self.annotation_type == 'report_design'
  end

  def report_design_text_footer(language)
    footer = []
    prefixes = {
      whatsapp: 'WhatsApp: ',
      facebook: 'FB Messenger: m.me/',
      twitter: 'Twitter: twitter.com/',
      telegram: 'Telegram: t.me/',
      viber: 'Viber: ',
      line: 'LINE: '
    }
    [:signature, :whatsapp, :facebook, :twitter, :telegram, :viber, :line].each do |field|
      value = self.report_design_team_setting_value(field.to_s, language)
      footer << "#{prefixes[field]}#{value}" unless value.blank?
    end
    footer.join("\n")
  end

  def report_design_text(language = nil)
    if self.annotation_type == 'report_design'
      text = []
      title = self.report_design_field_value('title', language)
      text << "*#{title.strip}*" unless title.blank?
      text << Bot::Smooch.utmize_urls(self.report_design_field_value('text', language).to_s, 'report')
      url = self.report_design_field_value('published_article_url', language)
      text << Bot::Smooch.utmize_urls(url, 'report') unless url.blank?
      unless language.nil?
        footer = self.report_design_text_footer(language)
        text << footer if !footer.blank? && self.report_design_team_setting_value('use_signature', language)
      end
      text.join("\n\n")
    end
  end

  def report_design_field_value(field, language = nil)
    value = nil
    default = nil
    if self.annotation_type == 'report_design'
      data = self.data.with_indifferent_access
      default_language = data[:default_language] || self.annotated&.team&.default_language || 'en'
      data[:options].to_a.each do |option|
        value = option[field] if option[:language] == language
        default = option[field] if option[:language] == default_language
      end
    end
    value.blank? ? default : value
  end

  def report_design_image_url(language = nil)
    self.annotation_type == 'report_design' ? Dynamic.find(self.id).report_design_field_value('visual_card_url', language) : nil
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
    {
      title: self.report_design_field_value('headline', language),
      status: self.report_design_field_value('status_label', language),
      description: self.report_design_field_value('description', language),
      url: self.report_design_field_value('url', language),
      whatsapp: self.report_design_team_setting_value('whatsapp', language),
      facebook: facebook.blank? ? nil : "m.me/#{facebook}",
      twitter: twitter.blank? ? nil : "@#{twitter}",
      telegram: telegram.blank? ? nil : "t.me/#{telegram}",
      viber: self.report_design_team_setting_value('viber', language),
      line: self.report_design_team_setting_value('line', language)
    }
  end

  def report_image_generate_png(option_index)
    if self.annotation_type == 'report_design'
      team = self.annotated&.team
      data = self.data.with_indifferent_access
      language = data[:options][option_index][:language]

      # Get the template and generate the HTML
      FileUtils.mkdir_p(File.join(Rails.root, 'public', 'report_design'))
      template = team.get_report_design_image_template
      doc = Nokogiri::HTML(template)
      body = doc.at_css('body')
      overlay = self.report_design_field_value('dark_overlay', language) ? 'dark' : 'light'
      body['class'] = ['report', language.to_s, overlay].join(' ')
      html = doc.at_css('html')
      html['lang'] = language.to_s
      self.report_design_placeholders(language).each do |key, value|
        el = doc.at_css('#' + key.to_s)
        value.blank? ? el.remove : el.add_child(value)
      end
      date = self.report_design_field_value('date', language)
      doc.at_css('#date').content = date || self.report_design_date(self.updated_at.to_date, language)
      avatar = self.adjust_report_design_image_url(team.avatar)
      image = self.adjust_report_design_image_url(self.report_design_field_value('image', language))
      temp_name = 'temp-' + self.id.to_s + '-' + language + '.html'
      temp = File.join(Rails.root, 'public', 'report_design', temp_name)
      output = File.open(temp, 'w+')
      output.puts doc.to_s.gsub(/#CCCCCC/, self.report_design_field_value('theme_color', language).to_s).gsub('%IMAGE_URL%', image.to_s).gsub('%AVATAR_URL%', avatar.to_s)
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
      data[:options][option_index][:visual_card_url] = screenshot
      self.set_fields = data.to_json
      self.save!
      FileUtils.rm_f temp
      CheckS3.delete(path)
    end
  end

  def copy_report_image_paths
    return unless self.saved_change_to_file?
    fields = self.set_fields || '{}'
    data = { 'options' => [] }.merge(JSON.parse(fields))
    self.file.each_with_index do |image, i|
      next if image.blank?
      url = begin image.file.public_url rescue nil end
      data['options'][i]['image'] = url unless url.nil?
    end
    self.set_fields = data.to_json
    self.action = nil
    self.save!
  end

  def sent_count
    if self.annotation_type == 'report_design'
      pmids = self.annotated.related_items_ids
      DynamicAnnotation::Field.joins(:annotation).where(field_name: 'smooch_report_received', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => pmids).count
    end
  end
end
