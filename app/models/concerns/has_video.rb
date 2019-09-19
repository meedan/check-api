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
end