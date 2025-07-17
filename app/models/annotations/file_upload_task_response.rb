class FileUploadTaskResponse < Dynamic
  mount_uploaders :file, GenericFileUploader

  def class_name
    'Dynamic'
  end

  def self.max_size
    UploadedFile.get_max_size({ env: ENV['MAX_UPLOAD_SIZE'], config: CheckConfig.get('uploaded_file_max_size', nil, :integer), default: 20.megabytes })
  end

  # Re-define class variables from parent class
  @custom_optimistic_locking_options = Dynamic.custom_optimistic_locking_options
end
