require 'active_support/concern'

module TiplineNewsletterAudio
  extend ActiveSupport::Concern

  # Audio less than 10 MB (WhatsApp supports 16 MB for video, let's be safe when converting this audio to a video)
  def validate_header_file_audio
    size_in_mb = (self.header_file.file.size.to_f / (1000 * 1000))
    allowed_types = ['mp3', 'ogg', 'wav']
    type = self.header_file.file.extension.downcase
    errors.add(:base, I18n.t('errors.messages.audio_too_large', { max_size: '10MB' })) if size_in_mb > 10.0
    errors.add(:header_file, I18n.t('errors.messages.extension_white_list_error', { extension: type, allowed_types: allowed_types.join(', ') })) unless allowed_types.include?(type)
  end

  def should_convert_header_audio?
    self.header_type == 'audio' && self.new_file_uploaded?
  end

  # WhatsApp doesn't support audio... only supports video, with H.264 video codec and AAC audio codec
  # ffmpeg -loop 1 -i wave.jpg -i zap.mp3 -c:a aac -c:v libx264 -shortest audio7.mp4
  def convert_header_file_audio
    now = Time.now.to_i
    input = File.open(File.join(Rails.root, 'tmp', "newsletter-audio-input-#{self.id}-#{now}"), 'wb')
    input.puts(URI(self.header_file_url).open.read)
    input.close
    cover_path = File.join(Rails.root, 'public', 'images', 'newsletter_audio_header.png')
    output_path = File.join(Rails.root, 'tmp', "newsletter-audio-output-#{self.id}-#{now}.mp4")
    video = FFMPEG::Movie.new(input.path)
    video.transcode(output_path, ['-loop', '1', '-i', cover_path, '-c:a', 'aac', '-c:v', 'libx264', '-shortest'])
    path = "newsletter/video/newsletter-audio-#{self.id}-#{now}"
    CheckS3.write(path, 'video/mp4', File.read(output_path))
    FileUtils.rm_f input.path
    FileUtils.rm_f output_path
    CheckS3.public_url(path)
  end
end
