class UploadedVideo < Media
  include HasVideo

  def picture
    self.embed_path
  end

  def media_type
    'uploaded video'
  end
end
