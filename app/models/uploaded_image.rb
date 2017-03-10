class UploadedImage < Media
  include HasImage

  def picture
    self.image_path
  end
end
