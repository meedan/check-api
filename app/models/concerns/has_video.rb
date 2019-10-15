require 'active_support/concern'

module HasVideo
  extend ActiveSupport::Concern

  included do
    include HasFile

    mount_uploader :file, VideoUploader
    process_in_background :file
    validates :file, size: true, file_size: { less_than: UploadedVideo.max_size, message: "size should be less than #{UploadedVideo.max_size_readable}" }, allow_blank: true
  end

  def file_path
    "#{CONFIG['checkdesk_base_url']}/#{self.file_url}"
  end

  def thumbnail_path
    "#{CONFIG['checkdesk_base_url']}/#{self.image_path('thumb')}"
  end

  def embed_path
    "#{CONFIG['checkdesk_base_url']}/#{self.image_path('embed')}"
  end
end
