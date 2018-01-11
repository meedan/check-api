class UploadedFile < Media
  include HasFile
  mount_uploader :file, FileUploader

  def media_type
    'uploaded file'
  end
end
