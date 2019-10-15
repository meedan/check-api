require 'active_support/concern'

module HasImage
  extend ActiveSupport::Concern

  included do
    include HasFile

    mount_uploader :file, ImageUploader
    process_in_background :file
    validates :file, size: true, file_size: { less_than: UploadedImage.max_size, message: "size should be less than #{UploadedImage.max_size_readable}" }, allow_blank: true
  end

  def file_path
    self.image_path
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

end
