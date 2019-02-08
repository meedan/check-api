Dynamic.class_eval do
  after_commit :copy_memebuster_image_paths, on: [:create, :update], if: proc { |a| a.annotation_type == 'memebuster' }

  private

  def copy_memebuster_image_paths
    urls = []
    self.file.each do |image|
      urls << CONFIG['checkdesk_base_url'] + image.url
    end
    self.get_field('memebuster_image').update_column(:value, urls.join(','))
  end
end
