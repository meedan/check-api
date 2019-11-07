class UploadedImage < Media
  include HasImage

  def picture
    self.image_path
  end

  def media_type
    'uploaded image'
  end
end
