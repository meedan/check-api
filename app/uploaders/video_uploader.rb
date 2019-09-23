class VideoUploader < FileUploader
  include CarrierWave::Video
  include CarrierWave::Video::Thumbnailer

  storage :file

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

  def full_filename(for_file)
    super.chomp(File.extname(super)) + '.mp4'
  end

  def filename
    original_filename.chomp(File.extname(original_filename)) + '.mp4'
  end

  def extension_whitelist
    VideoUploader.upload_extensions
  end

  def self.upload_extensions
    %w(avi mp4)
  end
end
