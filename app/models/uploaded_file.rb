class UploadedFile < Media
  include HasFile
  mount_uploader :file, FileUploader
end
