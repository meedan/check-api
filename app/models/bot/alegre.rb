class Bot::Alegre < ActiveRecord::Base

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name

  def self.run(body)
    json = JSON.parse(body)
    pm = ProjectMedia.where(id: json['data']['dbid']).last
    unless pm.nil?
      Bot::Alegre.default.get_language_from_alegre(pm.text, pm)
      pm.create_mt_annotation
    end
  end

  def self.valid_request?(request)
    request.base_url == CONFIG['checkdesk_base_url_private']
  end

  def self.default
    Bot::Alegre.where(name: 'Alegre Bot').last || Bot::Alegre.new
  end

  def profile_image
    CONFIG['checkdesk_base_url'] + self.avatar.url
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

  def get_source_language_for_alegre(text, target)
    field = self.get_dynamic_field_value(target, 'language', 'language')
    field.nil? ? Bot::Alegre.default.get_language_from_alegre(text, target) : field.value
  end

  def get_mt_from_alegre(target, author)
    text = target.text
    translations = []
    src_lang = self.get_source_language_for_alegre(text, target)
    languages = target.project.languages
    languages = languages - [src_lang]
    languages.each do |lang|
      begin
        response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: text, from: src_lang, to: lang }, CONFIG['alegre_token'])
        mt_text = response['data'] if response['type'] == 'mt' && !response['data'].blank?
      rescue
        mt_text = nil
      end
      translations << { lang: lang, text: mt_text } unless mt_text.nil?
    end
    self.update_machine_translation(target, translations, author) unless translations.blank?
    translations
  end

  def language_object(target, attr = nil)
    field = self.get_dynamic_field_value(target, 'language', 'language')
    return nil if field.nil?
    attr.nil? ? field : field.send(attr)
  end

  def get_dynamic_field_value(target, annotation_type, field_type)
    DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => annotation_type, 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: field_type).first
  end
  
  protected

  def save_language(target, lang)
    annotation = Dynamic.new
    annotation.annotated = target
    annotation.annotator = self
    annotation.annotation_type = 'language'
    annotation.disable_es_callbacks = Rails.env.to_s == 'test'
    annotation.set_fields = { language: lang }.to_json
    annotation.save!
    annotation.update_columns(annotator_id: self.id, annotator_type: 'Bot::Alegre')
    annotation
  end

  def update_machine_translation(target, translations, author)
    mt = target.annotations.where(annotation_type: 'mt').last
    unless mt.nil?
      mt = mt.load
      User.current = author
      mt.set_fields = {'mt_translations': translations.to_json}.to_json
      mt.disable_es_callbacks = Rails.env.to_s == 'test'
      mt.save!
      User.current = nil
      # Delete old versions
      mt_field = self.get_dynamic_field_value(target, 'mt', 'json')
      versions = mt_field.versions.to_a unless mt_field.nil?
      unless versions.blank?
        versions.pop
        versions.each{|v| v.skip_check_ability = true; v.destroy}
      end
    end
  end
end
