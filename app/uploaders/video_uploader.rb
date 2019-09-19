class VideoUploader < FileUploader
  include CarrierWave::Video
  include CarrierWave::Video::Thumbnailer

  process encode_video: [:mp4, callbacks: { after_transcode: :set_success } ]

  version :thumb do
    process thumbnail: [{format: 'png', quality: 10, size: 192, strip: true, logger: Rails.logger}]
  
    def full_filename for_file
      png_name for_file, version_name
    end
  end
  
  def png_name for_file, version_name
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.png}
  end

  def extension_white_list
    VideoUploader.upload_extensions
  end

  def self.upload_extensions
    %w(avi mp4)
  end
end
