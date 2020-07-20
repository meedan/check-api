class UploadedAudio < Media
  include HasAudio

  def picture
    # self.embed_path
  end

  def media_type
    'uploaded audio'
  end
end
