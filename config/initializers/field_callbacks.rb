Dynamic.class_eval do
  after_save :copy_memebuster_image_paths, if: proc { |a| a.annotation_type == 'memebuster' }

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
    self.get_field('memebuster_image').update_column(:value, urls.join(','))
  end
end
