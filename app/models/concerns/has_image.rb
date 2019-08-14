require 'active_support/concern'

module HasImage
  extend ActiveSupport::Concern

  included do
    include HasFile

    mount_uploader :file, ImageUploader
    validates :file, size: true, allow_blank: true
  end

  def embed_path
    self.image_path('embed')
  end

  def thumbnail_path
    self.image_path('thumbnail')
  end

  def should_generate_thumbnail?
    true
  end

  def image_path(version = nil)
    self.file_url(version).to_s.gsub(/^#{Regexp.escape(CONFIG['storage']['endpoint'])}/, CONFIG['storage']['public_endpoint'])
  end
end
