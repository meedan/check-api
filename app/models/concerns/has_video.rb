require 'active_support/concern'

module HasVideo
  extend ActiveSupport::Concern

  module ClassMethods
    def max_size
      self.get_max_size({env: ENV['MAX_VIDEO_SIZE'], config: CONFIG['video_file_max_size'], default: 20.megabyte})
    end
  end

  included do
    include HasFile

    mount_uploader :file, VideoUploader
    process_in_background :file
    validates :file, file_size: { less_than: UploadedVideo.max_size, message: "size should be less than #{UploadedVideo.max_size_readable}" }, allow_blank: true
  end

  def thumbnail_path
    self.image_path('thumb')
  end
end
