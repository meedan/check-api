class ImageUploader < FileUploader
  include CarrierWave::MiniMagick

  version :thumbnail, if: :media? do
    process resize_to_fit: CONFIG['image_thumbnail_size'] || [100, 100]
  end

  version :embed, if: :media? do
    process resize_to_fit: CONFIG['image_embed_size'] || [800, 600]
  end

  def default_url
    "/images/#{model.class.to_s.underscore}.png"
  end

  def extension_white_list
    ImageUploader.upload_extensions
  end

  def self.upload_extensions
    %w(jpg jpeg gif png)
  end

  protected

  def media?(_file)
    model.class.name == 'UploadedImage'
  end
end
