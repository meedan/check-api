class AudioUploader < FileUploader
  require 'taglib'

  version :thumbnail do
    process :audio_cover

    define_method :full_filename do |for_file|
      cover_name for_file, version_name
    end
  end

  def extension_whitelist
    AudioUploader.upload_extensions
  end

  def self.upload_extensions
    %w(mp3 wav ogg)
  end

  private

  def audio_cover
    extname = File.extname(current_path).delete('.')
    klass = if extname == 'wav'
              TagLib::RIFF::WAV
            else
              TagLib::MPEG
            end
    klass::File.open(current_path) do |file|
      tag = extname == 'mp3' ? file.id3v2_tag : file.tag
      save_audio_cover(tag) unless tag.nil?
    end
  end

  def save_audio_cover(tag)
    cover = tag.frame_list('APIC').first
    unless cover.nil?
      ext = cover.mime_type.rpartition('/')[2]
      tmp_path = File.join( File.dirname(current_path), "tmpfile.#{ext}" )
      File.open(tmp_path, "wb") { |f| f.write(cover.picture) }
      # convert to `jpg` extension
      if ext != 'jpg'
        image = MiniMagick::Image.new(tmp_path)
        image.format "jpg"
      end
      File.rename tmp_path, current_path
    end
    File.delete(current_path) if cover.nil?
  end

  def cover_name for_file, version_name
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.jpg}
  end

end
