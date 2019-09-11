class VideoUploader < FileUploader
  include CarrierWave::Video

  process encode_video: [:mp4, callbacks: { after_transcode: :set_success } ]

  def extension_white_list
    VideoUploader.upload_extensions
  end

  def self.upload_extensions
    %w(avi mp4)
  end
end
