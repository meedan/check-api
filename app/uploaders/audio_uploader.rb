class AudioUploader < FileUploader
  # include CarrierWave::MiniMagick

  # version :thumbnail, if: :should_generate_thumbnail? do
  #   process resize_to_fit: CONFIG['image_thumbnail_size'] || [100, 100]
  # end

  # version :embed, if: :should_generate_thumbnail? do
  #   process resize_to_fit: CONFIG['image_embed_size'] || [800, 600]
  # end


  def extension_white_list
    AudioUploader.upload_extensions
  end

  def self.upload_extensions
    %w(mp3 wav)
  end
end
