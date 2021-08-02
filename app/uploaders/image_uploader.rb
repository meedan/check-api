class ImageUploader < FileUploader
  include CarrierWave::MiniMagick

  def self.define_version(name, size)
    version name, if: :should_generate_thumbnail? do
      process resize_to_fit: size

      define_method :full_filename do |for_file|
        image_name for_file, version_name
      end
    end
  end

  define_version :thumbnail, (CheckConfig.get('image_thumbnail_size', [100, 100]))
  define_version :embed, (CheckConfig.get('image_embed_size', [800, 600]))

  def image_name(for_file, version_name)
    return nil unless self.parent_version.file.exists?
    for_file = Media.filename(self.parent_version) if model.is_a?(Media)
    %Q{#{version_name}_#{for_file}}
  end

  def default_url
    "/images/#{model.class.to_s.underscore}.png"
  end

  def extension_white_list
    ImageUploader.upload_extensions
  end

  def remove!
    super unless model.keep_file
  end

  def self.upload_extensions
    %w(jpg jpeg gif png)
  end

  protected

  def should_generate_thumbnail?(_file)
    model.respond_to?(:should_generate_thumbnail?) && model.should_generate_thumbnail?
  end
end
