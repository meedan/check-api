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
    %w(mp3 wav ogg m4a)
  end

  def audio_cover_art_mp3
    data = {}
    TagLib::MPEG::File.open(current_path) do |file|
      tag = file.id3v2_tag
      data = audio_cover_data(tag) unless tag.nil?
    end
    data
  end

  def audio_cover_art_wav
    data = {}
    TagLib::RIFF::WAV::File.open(current_path) do |file|
      tag = file.tag
      data = audio_cover_data(tag) unless tag.nil?
    end
    data
  end

  def audio_cover_art_ogg
    data = {}
    TagLib::Ogg::Vorbis::File.open(current_path) do |file|
      tag = file.tag
      unless tag.nil?
        fields = tag.field_list_map
        data = fields['METADATA_BLOCK_PICTURE']
        unless data.nil?
          decoded = Base64.decode64(data.first)
          # skip header length https://xiph.org/flac/format.html#metadata_block_picture
          data = {
            ext: 'png',
            cover: decoded[58..-1]
          }
        end
      end
    end
    data
  end

  def audio_cover_art_m4a
    data = {}
    TagLib::MP4::File.open(current_path) do |file|
      tag = file.tag
      unless tag.nil? || tag.item_map['covr'].nil?
        cover_art_list = tag.item_map['covr'].to_cover_art_list
        cover_art = cover_art_list.first
        data = {
          ext: cover_art.format == TagLib::MP4::CoverArt::JPEG ? 'jpeg' : 'png',
          cover: cover_art.data
        } unless cover_art.nil?
      end
    end
    data
  end

  private

  def audio_cover
    extname = File.extname(current_path).delete('.')
    method = "audio_cover_art_#{extname}"
    begin
      data = self.send(method) if self.respond_to?(method)
      save_audio_cover(data)
    rescue StandardError => e
      Rails.logger.error("[Audio Cover] Exception for file #{current_path}: #{e.message}")
    end
  end

  def audio_cover_data(tag)
    cover_art = tag.frame_list('APIC').first
    cover_art.nil? ? {} : { ext: cover_art.mime_type.rpartition('/')[2], cover: cover_art.picture }
  end

  def save_audio_cover(data)
    unless data[:cover].blank?
      tmp_path = File.join( File.dirname(current_path), "tmpfile.#{data[:ext]}" )
      File.open(tmp_path, "wb") { |f| f.write(data[:cover]) }
      # convert to `jpg` extension
      if data[:ext] != 'jpg'
        image = MiniMagick::Image.new(tmp_path)
        image.format "jpg"
      end
      File.rename tmp_path, current_path
    end
    File.delete(current_path) if data[:cover].nil?
  end

  def cover_name(_for_file, version_name)
    %Q{#{version_name}_#{Media.filename(self.parent_version, false)}.jpg}
  end

end
