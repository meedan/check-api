require 'active_support/concern'

module HasAudio
  extend ActiveSupport::Concern

  module ClassMethods
    def max_size
      self.get_max_size({ env: ENV['MAX_AUDIO_SIZE'], config: CheckConfig.get('audio_file_max_size', nil, :integer), default: 20.megabyte })
    end
  end

  included do
    include HasFile

    mount_uploader :file, AudioUploader
    validates :file, file_size: { less_than: UploadedAudio.max_size, message: :audio_too_large, max_size: UploadedAudio.max_size_readable }, allow_blank: true
  end

  def thumbnail_path
    self.image_path('thumbnail') if self.file.thumbnail.file.exists?
  end
end
