class ImageUploader < FileUploader
  include CarrierWave::MiniMagick

  version :thumbnail, if: :should_generate_thumbnail? do
    process resize_to_fit: CONFIG['image_thumbnail_size'] || [100, 100]
  end

  version :embed, if: :should_generate_thumbnail? do
    process resize_to_fit: CONFIG['image_embed_size'] || [800, 600]
  end

  def default_url(*args)
    "/images/#{model.class.to_s.underscore}.png"
  end

  def extension_white_list
    ImageUploader.upload_extensions
  end

  def self.upload_extensions
    %w(jpg jpeg gif png)
  end

  protected

  def should_generate_thumbnail?(_file)
    model.respond_to?(:should_generate_thumbnail?) && model.should_generate_thumbnail?
  end
end
