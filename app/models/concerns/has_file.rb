require 'active_support/concern'

module HasFile
  extend ActiveSupport::Concern

  def public_path
    self.file&.file&.public_url&.to_s&.gsub(/^#{Regexp.escape(CONFIG['storage']['endpoint'])}/, CONFIG['storage']['public_endpoint'])
  end

  def file_mandatory?
    true
  end

  module ClassMethods
    def max_size
      ENV['MAX_UPLOAD_SIZE'] ? Filesize.from("#{ENV['MAX_UPLOAD_SIZE']}B").to_f : (CONFIG['uploaded_file_max_size'] || 1.megabyte)
    end

    def max_size_readable
      Filesize.new(UploadedFile.max_size, Filesize::SI).pretty
    end
  end

  included do
    # Cannot mount_uploader here, because HasImage does too and they conflict.
    # Mount the FileUploader on the client site instead when you need it.
    validates :file, safe: true, allow_blank: true
    validates :file, presence: true, if: proc { |object| object.file_mandatory? }
    validates :file, file_size: { less_than: UploadedFile.max_size, message: "size should be less than #{UploadedFile.max_size_readable}" }, allow_blank: true
  end
end
