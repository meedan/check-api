class UploadedFile < Media
  mount_uploader :file, FileUploader

  validates :file, presence: true
  validates :file, file_size: { less_than: CONFIG['uploaded_file_max_size'] || 1.megabyte }

  def public_path
    CONFIG['checkdesk_base_url'] + self.file.url
  end
end
