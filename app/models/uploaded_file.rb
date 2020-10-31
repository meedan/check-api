class UploadedFile < Media
  include HasFile
  mount_uploader :file, FileUploader

  def media_type
    'uploaded file'
  end

  def self.max_size
    self.get_max_size({ env: ENV['MAX_UPLOAD_SIZE'], config: CONFIG['uploaded_file_max_size'], default: 2.megabytes })
  end
end
