require 'active_support/concern'

module HasImage
  extend ActiveSupport::Concern

  module ClassMethods
    def max_size
      ENV['MAX_UPLOAD_SIZE'] ? Filesize.from("#{ENV['MAX_UPLOAD_SIZE']}B").to_f : (CONFIG['uploaded_file_max_size'] || 1.megabyte)
    end
  end

  included do
    include HasFile

    mount_uploader :file, ImageUploader
    validates :file, size: true, file_size: { less_than: UploadedImage.max_size, message: "size should be less than #{UploadedImage.max_size_readable}" }, allow_blank: true
  end

  def thumbnail_path
    self.image_path('thumbnail')
  end

  def should_generate_thumbnail?
    true
  end

end
