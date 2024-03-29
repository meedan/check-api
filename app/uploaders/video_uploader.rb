class VideoUploader < FileUploader
  include CarrierWave::Video::Thumbnailer
  include ::CarrierWave::Backgrounder::Delay

  def self.define_version(name, size)
    version name do
      process thumbnail: [{ format: 'jpg', size: "#{size.first}x#{size.last}", quality: 10, logger: Rails.logger }]

      define_method :full_filename do |for_file|
        jpg_name for_file, version_name
      end
    end
  end

  define_version :thumb, (CheckConfig.get('image_thumbnail_size', [100, 100]))
  define_version :embed, (CheckConfig.get('image_embed_size', [800, 600]))

  def jpg_name(_for_file, version_name)
    %Q{#{version_name}_#{Media.filename(self.parent_version, false)}.jpg}
  end

  def extension_whitelist
    VideoUploader.upload_extensions
  end

  def self.upload_extensions
    %w(mp4 ogg ogv webm mov m4v)
  end
end
