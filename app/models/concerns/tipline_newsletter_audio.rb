require 'active_support/concern'

module TiplineNewsletterAudio
  extend ActiveSupport::Concern

  # Audio less than 10 MB (WhatsApp supports 16 MB for video, let's be safe when converting this audio to a video)
  def validate_header_file_audio
    self.validate_header_file(10, ['mp3', 'ogg', 'wav'], 'errors.messages.audio_too_large')
  end

  def should_convert_header_audio?
    self.header_type == 'audio' && self.new_file_uploaded?
  end

  # WhatsApp doesn't support audio... only supports video, with H.264 video codec and AAC audio codec
  def convert_header_file_audio
    self.convert_header_file_audio_or_video('audio')
  end
end
