require 'active_support/concern'

module TiplineNewsletterVideo
  extend ActiveSupport::Concern

  # MP4 less than 10 MB (WhatsApp supports 16 MB, let's be safe)
  def validate_header_file_video
    size_in_mb = (self.header_file.file.size.to_f / (1000 * 1000))
    allowed_types = ['mp4']
    type = self.header_file.file.extension.downcase
    errors.add(:base, I18n.t('errors.messages.video_too_large', { max_size: '10MB' })) if size_in_mb > 10.0
    errors.add(:header_file, I18n.t('errors.messages.extension_white_list_error', { extension: type, allowed_types: allowed_types.join(', ') })) unless allowed_types.include?(type)
  end

  def should_convert_header_video?
    self.header_type == 'video' && self.new_file_uploaded?
  end

  # WhatsApp only supports H.264 video codec and AAC audio codec
  def convert_header_file_video
    now = Time.now.to_i
    input = File.open(File.join(Rails.root, 'tmp', "newsletter-video-input-#{self.id}-#{now}.mp4"), 'wb')
    input.puts(URI(self.header_file_url).open.read)
    input.close
    output_path = File.join(Rails.root, 'tmp', "newsletter-video-output-#{self.id}-#{now}.mp4")
    video = FFMPEG::Movie.new(input.path)
    video.transcode(output_path, { video_codec: 'libx264', audio_codec: 'aac' })
    path = "newsletter/video/newsletter-video-#{self.id}-#{now}"
    CheckS3.write(path, 'video/mp4', File.read(output_path))
    FileUtils.rm_f input.path
    FileUtils.rm_f output_path
    CheckS3.public_url(path)
  end
end
