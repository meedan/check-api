Dynamic.class_eval do
  def report_design_introduction(data)
    if self.annotation_type == 'report_design'
      lang = data['language'] || 'en'
      introduction = self.get_field_value('introduction')
      introduction = introduction.gsub('{{status}}', self.get_field_value('status_label')) if self.get_field_value('status_label')
      introduction = introduction.gsub('{{query_date}}', ::I18n.l(Time.at(data['received']), locale: lang, format: :short)) if data['received']
      introduction = introduction.gsub('{{query_message}}', data['text']) if data['text']
      introduction
    end
  end

  def report_design_text
    if self.annotation_type == 'report_design'
      text = []
      text << self.get_field_value('text')
      text << self.get_field_value('disclaimer') if self.get_field_value('use_disclaimer')
      text.join("\n\n")
    end
  end

  def report_design_image_url
    self.annotation_type == 'report_design' ? Dynamic.find(self.id).get_field_value('visual_card_url') : nil
  end

  def adjust_report_design_image_url(url)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    (ENV['RAILS_ENV'] == 'development' && url =~ /^#{CONFIG['storage']['asset_host']}/) ? url.gsub(CONFIG['storage']['asset_host'], "#{CONFIG['storage']['endpoint']}/#{CONFIG['storage']['bucket']}") : url
  end

  def report_image_generate_png
    if self.annotation_type == 'report_design'
      team = self.annotated&.project&.team
      return if team.nil?

      # Get the template and generate the HTML
      FileUtils.mkdir_p(File.join(Rails.root, 'public', 'report_design'))
      template = team.get_report_design_image_template
      text = {
        title: self.get_field_value('headline'),
        status: self.get_field_value('status_label'),
        description: self.get_field_value('description')
      }
      language = ::Bot::Alegre.get_language_from_alegre(text.values.map(&:to_s).join("\n"))
      doc = Nokogiri::HTML(template)
      body = doc.at_css('body')
      body['class'] = language.to_s
      html = doc.at_css('html')
      html['lang'] = language.to_s
      title = doc.at_css('#title')
      title.content = text[:title]
      status = doc.at_css('#status')
      status.content = text[:status]
      description = doc.at_css('#description')
      description.content = text[:description]
      url = doc.at_css('#url')
      url.content = self.get_field_value('url')
      avatar = self.adjust_report_design_image_url(team.avatar)
      image = self.adjust_report_design_image_url(self.get_field_value('image'))
      temp_name = 'temp-' + SecureRandom.hex(16) + '-' + self.id.to_s
      temp = File.join(Rails.root, 'public', 'report_design', temp_name)
      output = File.open("#{temp}.html", 'w+')
      output.puts doc.to_s.gsub(/#CCCCCC/, self.get_field_value('theme_color')).gsub('%IMAGE_URL%', image).gsub('%AVATAR_URL%', avatar)
      output.close

      # Convert the HTML to PNG
      temp_url = "#{CONFIG['checkdesk_base_url']}/report_design/#{temp_name}.html"
      screenshot = JSON.parse(Net::HTTP.get_response(URI("#{CONFIG['screenshot_service_url']}/?url=#{temp_url}&selector=%23frame")).body)['url']
      raise "Unexpected response from screenshot service: #{screenshot}" unless screenshot =~ /^http/
      self.set_fields = self.data.merge({ visual_card_url: screenshot }).to_json
      self.save!

      FileUtils.rm_f "#{temp}.html"
    end
  end

  def copy_report_image_paths
    data = {}
    unless self.set_fields.blank?
      data = JSON.parse(self.set_fields)
      return unless data['image'].blank?
    end
    urls = []
    self.file.each do |image|
      url = begin image.file.public_url rescue nil end
      urls << url unless url.nil?
    end
    value = urls.join(',')
    self.set_fields = data.merge({ image: value }).to_json
    self.action = nil
    self.save!
  end
end
