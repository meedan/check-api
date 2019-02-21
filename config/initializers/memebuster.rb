require 'webshot'

Dynamic.class_eval do
  after_save :copy_memebuster_image_paths, if: proc { |a| a.annotation_type == 'memebuster' }

  def memebuster_png_path(force = false)
    if self.annotation_type == 'memebuster'
      filename = "#{self.id}.png"
      filepath = File.join(Rails.root, 'public', 'memebuster', filename)
      url = CONFIG['checkdesk_base_url'] + '/memebuster/' + filename
      
      if !File.exist?(filepath) || force
        team = self.annotated&.project&.team
        return if team.nil?
        params = {}
        DynamicAnnotation::Field.where(annotation_id: self.id).each do |f|
          params[f.field_name.gsub(/^memebuster_/, '').to_sym] = f.to_s.gsub(/<\/?[^>]+>/, '')
        end
        template = team.get_memebuster_template
        doc = Nokogiri::XML(template)
        image = doc.at_css('#image')
        image['xlink:href'] = params[:image]
        overlay = doc.at_css('#overlay')
        overlay['style'] = overlay['style'].to_s.gsub(/fill:\s*[^;]+/, "fill: #{params[:overlay]}")
        status = doc.at_css('#statusText')
        status['style'] = status['style'].to_s.gsub(/fill:\s*[^;]+/, "fill: #{params[:overlay]}")
        status.content = params[:status]
        headline = doc.at_css('#headline')
        headline.content = params[:headline]
        description = doc.at_css('#description')
        description.content = params[:body]
        team_name = doc.at_css('#teamName')
        team_name.content = team.name
        team_url = doc.at_css('#teamUrl')
        team_url.content = team.url
        team_image = doc.at_css('#teamAvatar')
        team_image['xlink:href'] = team.avatar
        
        temp_name = 'temp-' + SecureRandom.hex(16) + self.id.to_s
        temp = File.join(Rails.root, 'public', 'memebuster', temp_name)
        output = File.open("#{temp}.svg", 'w+')
        output.puts doc.to_s
        output.close
        
        screenshot = Webshot::Screenshot.instance
        screenshot.capture "#{CONFIG['checkdesk_base_url_private']}/memebuster/#{temp_name}.svg", "#{temp}.png", width: 500, height: 500
      
        File.atomic_write(filepath) { |file| file.write(File.read("#{temp}.png")) }
        FileUtils.rm_f "#{temp}.svg"
        FileUtils.rm_f "#{temp}.png"
      end
      
      url
    end
  end

  private

  def copy_memebuster_image_paths
    unless self.set_fields.blank?
      data = JSON.parse(self.set_fields)
      return unless data['memebuster_image'].blank?
    end
    urls = []
    self.file.each do |image|
      urls << CONFIG['checkdesk_base_url'] + image.url
    end
    field = self.get_field('memebuster_image')
    field.update_column(:value, urls.join(',')) unless field.nil?
  end
end
