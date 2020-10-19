Dynamic.class_eval do
  before_validation do
    self.keep_file = true if self.annotation_type == 'report_design'
  end

  def report_design_introduction(data, language)
    if self.annotation_type == 'report_design'
      introduction = self.report_design_field_value('introduction', language).to_s
      introduction = introduction.gsub('{{status}}', self.report_design_field_value('status_label', language).to_s)
      introduction = introduction.gsub('{{query_date}}', self.report_design_date(Time.at(data['received']).to_date, language)) if data['received']
      introduction
    end
  end

  def report_design_text(language)
    if self.annotation_type == 'report_design'
      text = []
      title = self.report_design_field_value('title', language)
      text << "*#{title}*" unless title.blank?
      text << self.report_design_field_value('text', language)
      disclaimer = self.report_design_field_value('disclaimer', language)
      text << "_#{disclaimer}_" unless disclaimer.blank?
      text.join("\n\n")
    end
  end

  def report_design_field_value(field, language)
    value = nil
    default = nil
    default_language = self.annotated&.team&.get_language || 'en'
    if self.annotation_type == 'report_design'
      self.data.with_indifferent_access[:options].each do |option|
        value = option[field] if option[:language] == language
        default = option[field] if option[:language] == default_language
      end
    end
    value.blank? ? default : value
  end

  def report_design_image_url(language)
    self.annotation_type == 'report_design' ? Dynamic.find(self.id).report_design_field_value('visual_card_url', language) : nil
  end

  def adjust_report_design_image_url(url)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    (ENV['RAILS_ENV'] == 'development' && url =~ /^#{CONFIG['storage']['asset_host']}/) ? url.gsub(CONFIG['storage']['asset_host'], "#{CONFIG['storage']['endpoint']}/#{CONFIG['storage']['bucket']}") : url
  end

  def report_design_date(date, language)
    I18n.l(date, locale: language.to_s.tr('_', '-'), format: :long)
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
      {
        title: self.report_design_field_value('headline', language),
        status: self.report_design_field_value('status_label', language),
        description: self.report_design_field_value('description', language),
        url: self.report_design_field_value('url', language)
      }.each do |key, value|
        el = doc.at_css('#' + key.to_s)
        value.blank? ? el.remove : (el.content = value)
      end
      date = self.report_design_field_value('date', language)
      doc.at_css('#date').content = date || self.report_design_date(self.updated_at.to_date, language)
      avatar = self.adjust_report_design_image_url(team.avatar)
      image = self.adjust_report_design_image_url(self.report_design_field_value('image', language))
      temp_name = 'temp-' + self.id.to_s + '-' + language + '.html'
      temp = File.join(Rails.root, 'public', 'report_design', temp_name)
      output = File.open(temp, 'w+')
      output.puts doc.to_s.gsub(/#CCCCCC/, self.report_design_field_value('theme_color', language)).gsub('%IMAGE_URL%', image).gsub('%AVATAR_URL%', avatar)
      output.close

      # Upload the HTML to S3
      path = "report_design/#{temp_name}"
      CheckS3.write(path, 'text/html', File.read(temp))
      temp_url = CheckS3.public_url(path)

      # Convert the HTML to PNG
      uri = URI("#{CONFIG['narcissus_url']}/?url=#{temp_url}&selector=%23frame")
      request = Net::HTTP::Get.new(uri)
      request['x-api-key'] = CONFIG['narcissus_token']
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
      screenshot = JSON.parse(response.body)['url']
      raise "Unexpected response from screenshot service: #{screenshot}" unless screenshot =~ /^http/
      data[:options][option_index][:visual_card_url] = screenshot
      self.set_fields = data.to_json
      self.save!
      FileUtils.rm_f temp
      CheckS3.delete(path)
    end
  end

  def copy_report_image_paths
    return unless self.file_changed?
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
      DynamicAnnotation::Field.joins(:annotation).where(field_name: 'smooch_report_received', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => self.annotated_id).count
    end
  end
end
