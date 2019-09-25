require 'active_support/concern'

module HasFile
  extend ActiveSupport::Concern

  def public_path
    self.file&.file&.public_url&.to_s&.gsub(/^#{Regexp.escape(CONFIG['storage']['endpoint'])}/, CONFIG['storage']['public_endpoint'])
  end

  def file_mandatory?
    true
  end

  def image_path(version = nil)
    self.file_url(version).to_s.gsub(/^#{Regexp.escape(CONFIG['storage']['endpoint'])}/, CONFIG['storage']['public_endpoint'])
  end

  module ClassMethods
    def max_size
      if (self.name == 'UploadedVideo')
        size = ENV['MAX_VIDEO_SIZE'] ? Filesize.from("#{ENV['MAX_VIDEO_SIZE']}B").to_f : (CONFIG['video_file_max_size'] || 20.megabyte)
      else
        size = ENV['MAX_UPLOAD_SIZE'] ? Filesize.from("#{ENV['MAX_UPLOAD_SIZE']}B").to_f : (CONFIG['uploaded_file_max_size'] || 1.megabyte)
      end
      size
    end

    def max_size_readable
      Filesize.new(self.max_size, Filesize::SI).pretty
    end
  end

  included do
    # Cannot mount_uploader here, because HasImage does too and they conflict.
    # Mount the FileUploader on the client site instead when you need it.
    validates :file, safe: true, allow_blank: true
    validates :file, presence: true, if: proc { |object| object.file_mandatory? }
  end
end
