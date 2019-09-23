require 'active_support/concern'

module HasVideo
  extend ActiveSupport::Concern

  included do
    include HasFile

    mount_uploader :file, VideoUploader
    # validates :file, size: true, allow_blank: true
  end

  def set_success(format, opts)
    # TODO: mark success operation
  end

  def video_path
  	"#{CONFIG['checkdesk_base_url']}/#{self.file_url}"
  end

  def thumbnail_path
    "#{CONFIG['checkdesk_base_url']}/#{self.image_path('thumb')}"
  end
end