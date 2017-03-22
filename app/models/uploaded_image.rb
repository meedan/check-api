class UploadedImage < Media
  include HasImage

  def picture
    self.image_path
  end

  def media_url
    "#{CONFIG['checkdesk_base_url']}#{self.file.url}"
  end
end
