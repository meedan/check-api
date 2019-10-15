class VideoUploader < FileUploader
  include CarrierWave::Video
  include CarrierWave::Video::Thumbnailer
  include CarrierWave::MiniMagick
  include ::CarrierWave::Backgrounder::Delay

  version :thumb do
    s = CONFIG['image_thumbnail_size'] || [100, 100]
    process thumbnail: [{format: 'jpg', size: "#{s.first}x#{s.last}", quality: 10, logger: Rails.logger}]

    def full_filename for_file
      jpg_name for_file, version_name
    end

  end

  version :embed do
    s = CONFIG['image_embed_size'] || [800, 600]
    process thumbnail: [{format: 'jpg', size: "#{s.first}x#{s.last}", quality: 10, logger: Rails.logger}]

    def full_filename for_file
      jpg_name for_file, version_name
    end

  end

  def jpg_name for_file, version_name
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.jpg}
  end

  def extension_whitelist
    VideoUploader.upload_extensions
  end

  def self.upload_extensions
    %w(mp4 ogg ogv webm mov m4v)
  end

end
