class FileUploader < CarrierWave::Uploader::Base
  if defined?(CarrierWave::Storage::Fog)
    storage :fog
  end

  def store_dir
    klass = model.is_a?(FileUploadTaskResponse) ? model.class_name : model.class.to_s
    "uploads/#{klass.underscore}/#{model.id}"
  end
end
