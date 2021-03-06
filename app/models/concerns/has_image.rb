require 'active_support/concern'

module HasImage
  extend ActiveSupport::Concern

  module ClassMethods
    def max_size
      self.get_max_size({ env: ENV['MAX_UPLOAD_SIZE'], config: CheckConfig.get('uploaded_file_max_size', nil, :integer), default: 1.megabyte })
    end
  end

  included do
    include HasFile

    mount_uploader :file, ImageUploader
    validates :file, size: true, file_size: { less_than: UploadedImage.max_size, message: :image_too_large, max_size: UploadedImage.max_size_readable }, allow_blank: true
  end

  def thumbnail_path
    self.image_path('thumbnail')
  end

  def should_generate_thumbnail?
    true
  end
end
