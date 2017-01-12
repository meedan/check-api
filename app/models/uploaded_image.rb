class UploadedImage < UploadedFile
  mount_uploader :file, ImageUploader
  
  validates :file, size: true
end
