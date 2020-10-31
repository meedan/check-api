class FileUploadTaskResponse < Dynamic
  mount_uploaders :file, GenericFileUploader

  def class_name
    'Dynamic'
  end

  # Re-define class variables from parent class
  @pusher_options = Dynamic.pusher_options
  @custom_optimistic_locking_options = Dynamic.custom_optimistic_locking_options
end
