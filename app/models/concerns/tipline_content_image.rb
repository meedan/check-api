require 'active_support/concern'

module TiplineContentImage
  extend ActiveSupport::Concern

  # PNG or JPG less than 5 MB
  def validate_header_file_image
    self.validate_header_file(5, ['png', 'jpg', 'jpeg'], 'errors.messages.image_too_large')
  end

  def should_convert_header_image?
    # New file or new overlay text
    self.header_type == 'image' && (self.new_file_uploaded? || self.previous_changes.keys.include?('header_overlay_text'))
  end

  def convert_header_file_image
    return self.header_file_url if self.header_overlay_text.blank?

    screenshot = temp = path = nil
    content_name = self.class.content_name
    begin
      # Get the template and generate the HTML
      FileUtils.mkdir_p(File.join(Rails.root, 'public', content_name))
      doc = Nokogiri::HTML(File.read(File.join(Rails.root, 'public', 'tipline-content-template.html')))
      body = doc.at_css('body')
      body['class'] = ['content', self.language].join(' ')
      html = doc.at_css('html')
      html['lang'] = self.language
      doc.at_css('#text').content = self.header_overlay_text
      temp_name = 'temp-' + self.id.to_s + '-' + self.language + '.html'
      temp = File.join(Rails.root, 'public', content_name, temp_name)
      output = File.open(temp, 'w+')

      # Replace the image in the template
      image_url = CheckS3.rewrite_url(self.header_file_url.to_s)
      w, h = ::MiniMagick::Image.open(image_url)[:dimensions]
      image_class = w > h ? 'wider' : 'taller'
      output.puts doc.to_s.gsub('%IMAGE_URL%', image_url).gsub('%IMAGE_CLASS%', image_class)
      output.close

      # Upload the HTML to S3
      path = "#{content_name}/#{temp_name}"
      CheckS3.write(path, 'text/html', File.read(temp))
      temp_url = CheckS3.public_url(path)

      # Convert the HTML to PNG
      uri = URI("#{CheckConfig.get('narcissus_url')}/?selector=img&url=#{CheckS3.rewrite_url(temp_url)}")
      request = Net::HTTP::Get.new(uri)
      request['x-api-key'] = CheckConfig.get('narcissus_token')
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
      screenshot = JSON.parse(response.body)['url']
      raise "Unexpected response from Narcissus for #{uri}: #{response.body}" unless screenshot =~ /^http/
    rescue StandardError => e
      CheckSentry.notify(e)
    ensure
      FileUtils.rm_f temp
      CheckS3.delete(path)
    end
    screenshot
  end
end
