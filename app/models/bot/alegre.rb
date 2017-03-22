class Bot::Alegre < ActiveRecord::Base
  def self.default
    Bot::Alegre.where(name: 'Alegre Bot').last
  end

  def get_language_from_alegre(text, target)
    lang = nil
    if !text.blank? && !CONFIG['alegre_host'].blank? && !CONFIG['alegre_token'].blank?
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
