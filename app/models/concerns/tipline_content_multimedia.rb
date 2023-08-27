require 'active_support/concern'

# Attached file: image, audio or video

module TiplineContentMultimedia
  extend ActiveSupport::Concern

  included do
    include TiplineContentImage
    include TiplineContentVideo
    include TiplineContentAudio

    mount_uploader :header_file, FileUploader

    validates_inclusion_of :header_type, in: ['none', 'link_preview', 'audio', 'video', 'image']
    validate :header_file_is_supported_by_whatsapp

    after_commit :convert_header_file, on: [:create, :update]
  end

  # File uploads through GraphQL require this setter
  # Accepts an array or a single file, but persists only one file
  def file=(file)
    @file_set = true
    self.header_file = [file].flatten.first
  end

  def new_file_uploaded?
    !!@file_set
  end

  # Converts an audio or video file to a video with the specific codecs supported by WhatsApp
  def convert_header_file_audio_or_video(type)
    options = nil
    content_name = self.class.content_name # "newsletter" or "resource"
    if type == 'audio'
      cover_path = File.join(Rails.root, 'public', 'images', 'tipline_audio_header.png')
      options = ['-loop', '1', '-i', cover_path, '-c:a', 'aac', '-c:v', 'libx264', '-shortest']
    elsif type == 'video'
      options = { video_codec: 'libx264', audio_codec: 'aac' }
    end
    url = nil
    input = nil
    output_path = nil
    begin
      now = Time.now.to_i
      input = File.open(File.join(Rails.root, 'tmp', "#{content_name}-#{type}-input-#{self.id}-#{now}"), 'wb')
      input.puts(URI(self.header_file_url).open.read)
      input.close
      output_path = File.join(Rails.root, 'tmp', "#{content_name}-#{type}-output-#{self.id}-#{now}.mp4")
      video = FFMPEG::Movie.new(input.path)
      video.transcode(output_path, options)
      path = "#{content_name}/video/#{content_name}-#{type}-#{self.id}-#{now}"
      CheckS3.write(path, 'video/mp4', File.read(output_path))
      url = CheckS3.public_url(path)
    rescue StandardError => e
      CheckSentry.notify(e)
    ensure
      FileUtils.rm_f input.path
      FileUtils.rm_f output_path
    end
    url
  end

  module ClassMethods
    def convert_header_file(id)
      obj = self.find(id)
      new_url = nil

      case obj.header_type
      when 'image'
        new_url = obj.convert_header_file_image
      when 'video'
        new_url = obj.convert_header_file_video
      when 'audio'
        new_url = obj.convert_header_file_audio
      end

      obj.update_column(:header_media_url, new_url) unless new_url.nil?
    end
  end

  private

  def header_file_is_supported_by_whatsapp
    if self.header_type && self.new_file_uploaded?
      case self.header_type
      when 'image'
        self.validate_header_file_image
      when 'video'
        self.validate_header_file_video
      when 'audio'
        self.validate_header_file_audio
      end
    end
  end

  def convert_header_file
    if self.should_convert_header_image? || self.should_convert_header_video? || self.should_convert_header_audio?
      self.class.delay_for(1.second, retry: 3).convert_header_file(self.id)
    end
  end

  def validate_header_file(max_size, allowed_types, message)
    size_in_mb = (self.header_file.file.size.to_f / (1000 * 1000))
    type = self.header_file.file.extension.downcase
    errors.add(:base, I18n.t(message, **{ max_size: "#{max_size}MB" })) if size_in_mb > max_size.to_f
    errors.add(:header_file, I18n.t('errors.messages.extension_white_list_error', **{ extension: type, allowed_types: allowed_types.join(', ') })) unless allowed_types.include?(type)
  end
end
