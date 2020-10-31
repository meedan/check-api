class GenericFileUploader < FileUploader
  def extension_whitelist
    GenericFileUploader.upload_extensions
  end

  def self.upload_extensions
    %w(pdf xslx csv txt) + AudioUploader.upload_extensions + ImageUploader.upload_extensions + VideoUploader.upload_extensions
  end
end
