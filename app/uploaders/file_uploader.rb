class FileUploader < CarrierWave::Uploader::Base
  if defined?(CarrierWave::Storage::Fog)
    storage :fog
  end

  def store_dir
    "uploads/#{model.class_name.underscore}/#{model.id}"
  end
end
