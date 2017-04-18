class MachineTranslationWorker
  include Sidekiq::Worker

  def perform(target, author)
    target = YAML::load(target)
    author = YAML::load(author)
    field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'language', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'language').first
    src_lang = field.value unless field.nil?
    mt = target.annotations.where(annotation_type: 'mt').last
    unless mt.nil? or src_lang.nil?
      translations = []
      text = target.text
      # Assume languages format is ['en', 'ar', ...]
      languages = target.project.settings[:languages] unless target.project.settings.nil?
      languages = languages - [src_lang] unless languages.nil?
      languages.each do |lang|
        begin
          response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: text, from: src_lang, to: lang }, CONFIG['alegre_token'])
          mt_text = response['type'] == 'mt' ? response['data'] : nil
        rescue
          mt_text = nil
        end
        unless mt_text.nil?
          lang_name = TwitterCldr::Shared::LanguageCodes.to_language(lang, :iso_639_1)
          lang_name = lang_name.blank? ? lang : lang_name.downcase
          translations << { lang: lang, lang_name: lang_name, text: mt_text }
        end
      end unless languages.nil?
      unless translations.blank?
        # Delete old versions
        mt_field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'mt', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'json').first
        mt_field.versions.destroy_all
        mt = mt.load
        User.current = author
        mt.set_fields = {'mt_translations': translations.to_json}.to_json
        mt.save!
      end
    end
  end

end
