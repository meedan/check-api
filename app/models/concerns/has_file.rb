require 'active_support/concern'

module HasFile
  extend ActiveSupport::Concern

  def public_path
    CONFIG['checkdesk_base_url'] + self.file.url
  end

  def file_mandatory?
    true
  end

  def skip_file_size
    self.respond_to?(:is_being_copied) && self.is_being_copied
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
    validates :file, presence: true, if: proc { |object| object.file_mandatory? }
    validates :file, safe: true, allow_blank: true
    validates :file, file_size: { less_than: UploadedFile.max_size, message: "size should be less than #{UploadedFile.max_size_readable}" }, allow_blank: true, unless: :skip_file_size
  end
end
