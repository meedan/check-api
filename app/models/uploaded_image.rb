class UploadedImage < UploadedFile
  mount_uploader :file, ImageUploader
  
  validates :file, size: true

  def embed_path
    self.image_path('embed')
  end

  def thumbnail_path
    self.image_path('thumbnail')
  end

  protected

  def image_path(version = '')
    CONFIG['checkdesk_base_url'] + self.file_url(version)
  end
end
