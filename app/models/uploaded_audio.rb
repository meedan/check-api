class UploadedAudio < Media
  include HasAudio

  def media_type
    'uploaded audio'
  end

  def file_path
    self.file_url
  end

  def embed_path
    return nil
  end

  def picture
    return nil
  end
end
