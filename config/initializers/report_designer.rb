require 'webshot'

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

  def report_design_image_filename
    "#{self.id}.png" if self.annotation_type == 'report_design'
  end

  def report_design_image_filepath
    "report_design/#{self.report_design_image_filename}" if self.annotation_type == 'report_design'
  end

  def report_design_image_url
    self.annotation_type == 'report_design' ? CheckS3.public_url(self.report_design_image_filepath) : nil
  end

  def adjust_report_design_image_url(url)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    (ENV['RAILS_ENV'] == 'development' && url =~ /^#{CONFIG['storage']['asset_host']}/) ? url.gsub(CONFIG['storage']['asset_host'], "#{CONFIG['storage']['endpoint']}/#{CONFIG['storage']['bucket']}") : url
  end

  def report_image_generate_png(force = false)
    if self.annotation_type == 'report_design'
      filename = self.report_design_image_filename
      filepath = 'report_design/' + filename

      if !CheckS3.exist?(filepath) || force
        team = self.annotated&.project&.team
        return if team.nil?
        FileUtils.mkdir_p(File.join(Rails.root, 'public', 'report_design'))
        template = team.get_report_design_image_template
        doc = Nokogiri::HTML(template)
        title = doc.at_css('#title')
        title.content = self.get_field_value('headline')
        status = doc.at_css('#status')
        status.content = self.get_field_value('status_label')
        description = doc.at_css('#description')
        description.content = self.get_field_value('description')
        url = doc.at_css('#url')
        url.content = self.get_field_value('url')
        avatar = self.adjust_report_design_image_url(team.avatar)
        image = self.adjust_report_design_image_url(self.get_field_value('image'))

        temp_name = 'temp-' + SecureRandom.hex(16) + self.id.to_s
        temp = File.join(Rails.root, 'public', 'report_design', temp_name)
        output = File.open("#{temp}.html", 'w+')
        output.puts doc.to_s.gsub(/#CCCCCC/, self.get_field_value('theme_color')).gsub('%IMAGE_URL%', image).gsub('%AVATAR_URL%', avatar)
        output.close

        screenshot = Webshot::Screenshot.instance
        screenshot.capture "#{CONFIG['checkdesk_base_url_private']}/report_design/#{temp_name}.html", "#{temp}.png", width: 500, height: 500

        CheckS3.write(filepath, 'image/png', File.read("#{temp}.png"))

        FileUtils.rm_f "#{temp}.html"
        FileUtils.rm_f "#{temp}.png"
      end

      CheckS3.public_url(filepath)
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
