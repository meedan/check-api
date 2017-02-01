class UploadedFile < Media
  mount_uploader :file, FileUploader

  validates :file, presence: true
  validates :file, safe: true

  def public_path
    CONFIG['checkdesk_base_url'] + self.file.url
  end

  def self.max_size
    ENV['MAX_UPLOAD_SIZE'] ? Filesize.from("#{ENV['MAX_UPLOAD_SIZE']}B").to_f : (CONFIG['uploaded_file_max_size'] || 1.megabyte)
  end
  
  validates :file, file_size: { less_than: UploadedFile.max_size, message: "size should be less than #{Filesize.new(UploadedFile.max_size, Filesize::SI).pretty}" }
end
