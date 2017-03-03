require 'active_support/concern'

module HasFile
  extend ActiveSupport::Concern

  def public_path
    CONFIG['checkdesk_base_url'] + self.file.url
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
    mount_uploader :file, FileUploader

    validates :file, presence: true, if: proc { |object| object.file_mandatory? }
    validates :file, safe: true, allow_blank: true
    validates :file, file_size: { less_than: UploadedFile.max_size, message: "size should be less than #{UploadedFile.max_size_readable}" }, allow_blank: true
  end
end
