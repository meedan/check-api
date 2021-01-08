class UploadedFile < Media
  include HasFile
  mount_uploader :file, FileUploader

  def media_type
    'uploaded file'
  end

  def self.max_size
    self.get_max_size({ env: ENV['MAX_UPLOAD_SIZE'], config: CheckConfig.get('uploaded_file_max_size', nil, :integer), default: 20.megabytes })
  end
end
