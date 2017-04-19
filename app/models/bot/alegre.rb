class Bot::Alegre < ActiveRecord::Base
  def self.default
    Bot::Alegre.where(name: 'Alegre Bot').last
  end

  def should_classify?(text)
    !text.blank? && !CONFIG['alegre_host'].blank? && !CONFIG['alegre_token'].blank?
  end

  def get_language_from_alegre(text, target)
    lang = nil
    if self.should_classify?(text)
      begin
        response = AlegreClient::Request.get_languages_identification(CONFIG['alegre_host'], { text: text }, CONFIG['alegre_token'])
        lang = response['data'][0][0].split(',').first.downcase if response['type'] == 'language'
      rescue
        lang = nil
      end
    end
    self.save_language(target, lang) unless lang.nil?
    lang
  end

  def get_mt_from_alegre(target, author)
    text = target.text
    translations = []
    field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'language', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'language').first
    src_lang = field.nil? ? Bot::Alegre.default.get_language_from_alegre(text, target) : field.value
    languages = target.project.get_languages
    languages = languages - [src_lang] unless languages.nil?
    languages.each do |lang|
      begin
        response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: text, from: src_lang, to: lang }, CONFIG['alegre_token'])
        mt_text = response['type'] == 'mt' ? response['data'] : nil
      rescue
        mt_text = nil
      end
      translations << { lang: lang, text: mt_text } unless mt_text.nil?
    end unless languages.nil?
    unless translations.blank?
      # Delete old versions
      mt_field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'mt', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'json').first
      mt_field.versions.destroy_all
      mt = mt.load
      User.current = author
      mt.set_fields = {'mt_translations': translations.to_json}.to_json
      mt.save!
      User.current = nil
    end
  end

  def language(target)
    field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'language', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'language').first
    if field.nil?
      nil
    else
      name = TwitterCldr::Shared::LanguageCodes.to_language(field.value, :iso_639_1)
      name.blank? ? field.value : name.downcase
    end
  end

  protected

  def save_language(target, lang)
    annotation = Dynamic.new
    annotation.annotated = target
    annotation.annotator = self
    annotation.annotation_type = 'language'
    annotation.set_fields = { language: lang }.to_json
    annotation.save!
    annotation.update_columns(annotator_id: self.id, annotator_type: 'Bot::Alegre')
  end
end
