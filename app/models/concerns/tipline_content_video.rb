require 'active_support/concern'

module TiplineContentVideo
  extend ActiveSupport::Concern

  # Max size that WhatsApp supports
  def header_file_video_max_size_whatsapp
    CheckConfig.get(:header_file_video_max_size_whatsapp, 16, :integer)
  end

  # Max size for Check (we need to convert it to H.264, so let's be safe and use a value less than what WhatsApp supports)
  def header_file_video_max_size_check
    CheckConfig.get(:header_file_video_max_size_check, 10, :integer)
  end

  def validate_header_file_video
    self.validate_header_file(self.header_file_video_max_size_check, ['mp4'], 'errors.messages.video_too_large')
  end

  def should_convert_header_video?
    self.header_type == 'video' && self.new_file_uploaded?
  end

  # WhatsApp only supports H.264 video codec and AAC audio codec
  def convert_header_file_video
    self.convert_header_file_audio_or_video('video')
  end
end
