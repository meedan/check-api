require 'active_support/concern'

module TiplineContentVideo
  extend ActiveSupport::Concern

  # MP4 less than 10 MB (WhatsApp supports 16 MB, let's be safe)
  def validate_header_file_video
    self.validate_header_file(10, ['mp4'], 'errors.messages.video_too_large')
  end

  def should_convert_header_video?
    self.header_type == 'video' && self.new_file_uploaded?
  end

  # WhatsApp only supports H.264 video codec and AAC audio codec
  def convert_header_file_video
    self.convert_header_file_audio_or_video('video')
  end
end
