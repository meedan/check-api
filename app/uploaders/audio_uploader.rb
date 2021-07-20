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
            elsif extname == 'ogg'
              TagLib::Ogg::Vorbis
            else
              TagLib::MPEG
            end
    klass::File.open(current_path) do |file|
      tag = extname == 'mp3' ? file.id3v2_tag : file.tag
      return if tag.nil?
      if extname == 'ogg'
        cover = nil
        fields = tag.field_list_map
        data = fields['METADATA_BLOCK_PICTURE']
        unless data.nil?
          decoded = Base64.decode64(data.first)
          # skip header length https://xiph.org/flac/format.html#metadata_block_picture
          cover = decoded[58..-1]
        end
        save_audio_cover(cover, extname)
      else
        cover = tag.frame_list('APIC').first unless tag.nil?
        save_audio_cover(cover, extname)
      end
    end
  end

  def save_audio_cover(cover, extname)
    unless cover.nil?
      ext = extname == 'ogg' ? 'png' : cover.mime_type.rpartition('/')[2]
      cover = cover.picture unless extname == 'ogg'
      tmp_path = File.join( File.dirname(current_path), "tmpfile.#{ext}" )
      File.open(tmp_path, "wb") { |f| f.write(cover) }
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
