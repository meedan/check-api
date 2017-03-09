class UploadedImage < UploadedFile
  include HasImage

  def picture
    self.image_path
  end
end
