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

  def file_path
    self.image_path
  end

  def embed_path
    self.image_path('embed')
  end

  module ClassMethods
    def max_size
      options = { var_name: 'MAX_UPLOAD_SIZE', config_name: 'uploaded_file_max_size', size: 1.megabyte}
      if (self.name == 'UploadedVideo')
        options = { var_name: 'MAX_VIDEO_SIZE', config_name: 'video_file_max_size', size: 20.megabyte }
      end
      ENV[options[:var_name]] ? Filesize.from("#{ENV[options[:var_name]]}B").to_f : (CONFIG[options[:config_name]] || options[:size])
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
