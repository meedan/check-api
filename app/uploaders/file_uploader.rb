class FileUploader < CarrierWave::Uploader::Base
	include ::CarrierWave::Backgrounder::Delay

  storage :fog

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end
end
