require 'active_support/concern'

module TiplineNewsletterImage
  extend ActiveSupport::Concern

  # PNG or JPG less than 5 MB
  def validate_header_file_image
    size_in_mb = (self.header_file.file.size.to_f / (1000 * 1000))
    allowed_types = ['png', 'jpg', 'jpeg']
    type = self.header_file.file.extension.downcase
    errors.add(:base, I18n.t('errors.messages.image_too_large', { max_size: '5MB'})) if size_in_mb > 5
    errors.add(:header_file, I18n.t('errors.messages.extension_white_list_error', { extension: type, allowed_types: allowed_types.join(', ') })) unless allowed_types.include?(type)
  end

  def should_convert_header_image?
    # New file or new overlay text
    self.header_type == 'image' && (@file || self.previous_changes.keys.include?('header_overlay_text'))
  end

  def convert_header_file_image
    return self.header_file_url if self.header_overlay_text.blank?

    # Get the template and generate the HTML
    FileUtils.mkdir_p(File.join(Rails.root, 'public', 'newsletter'))
    doc = Nokogiri::HTML(File.read(File.join(Rails.root, 'public', 'newsletter-template.html')))
    body = doc.at_css('body')
    body['class'] = ['newsletter', self.language].join(' ')
    html = doc.at_css('html')
    html['lang'] = self.language
    doc.at_css('#text').content = self.header_overlay_text
    temp_name = 'temp-' + self.id.to_s + '-' + self.language + '.html'
    temp = File.join(Rails.root, 'public', 'newsletter', temp_name)
    output = File.open(temp, 'w+')
    output.puts doc.to_s.gsub('%IMAGE_URL%', self.header_file_url.to_s)
    output.close

    # Upload the HTML to S3
    path = "newsletter/#{temp_name}"
    CheckS3.write(path, 'text/html', File.read(temp))
    temp_url = CheckS3.public_url(path)

    # Convert the HTML to PNG
    uri = URI("#{CheckConfig.get('narcissus_url')}/?url=#{temp_url}&selector=%23frame")
    request = Net::HTTP::Get.new(uri)
    request['x-api-key'] = CheckConfig.get('narcissus_token')
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    screenshot = JSON.parse(response.body)['url']
    raise "Unexpected response from Narcissus for #{uri}: #{response.body}" unless screenshot =~ /^http/
    FileUtils.rm_f temp
    CheckS3.delete(path)
    screenshot
  end
end
