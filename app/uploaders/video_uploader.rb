class VideoUploader < FileUploader
  include CarrierWave::Video
  include CarrierWave::Video::Thumbnailer
  include CarrierWave::MiniMagick

  storage :file

  version :thumb do
    process thumbnail: [{format: 'png', quality: 10}]
  
    def full_filename for_file
      png_name for_file, version_name
    end
  end
  
  def png_name for_file, version_name
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.png}
  end

  # version :embed, from_version: :thumb do
  #   process resize_to_fit: CONFIG['image_embed_size'] || [800, 600]
  # end

  def extension_whitelist
    VideoUploader.upload_extensions
  end

  def self.upload_extensions
    %w(avi mp4)
  end
end
