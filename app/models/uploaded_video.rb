class UploadedVideo < Media
  include HasVideo

  def media_type
    'uploaded video'
  end
end
