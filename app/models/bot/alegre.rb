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
    # Save machine translation
    self.save_machine_translation(lang, text, target)
    lang
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
    self.add_dynamic_annotations('language', target, { language: lang })
  end

  def save_machine_translation(src_lang, text, target)
    target_lan = ['AR']
    target_lan.each do |lang|
      response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: text, from: src_lang, to: lang }, CONFIG['alegre_token'])
      # TODO: get machine translation from response
      self.add_dynamic_annotations('machine_translation', target, {'machine_translation': 'machine translation text'})
    end
  end

  def add_dynamic_annotations(type, target, fields)
    annotation = Dynamic.new
    annotation.annotated = target
    annotation.annotator = self
    annotation.annotation_type = type
    annotation.set_fields = fields.to_json
    annotation.save!
    annotation.update_columns(annotator_id: self.id, annotator_type: 'Bot::Alegre')
  end

end
