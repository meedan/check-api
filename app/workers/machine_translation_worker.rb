class MachineTranslationWorker
  include Sidekiq::Worker

  def perform(target, bot)
    target = YAML::load(target)
    bot = YAML::load(bot)
    field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'language', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'language').first
    unless field.nil?
      translations = []
      src_lang = field.value
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
        translations << { lang: lang, text: mt_text } unless mt_text.nil?
      end unless languages.nil?
      unless translations.blank?
          annotation = Dynamic.new
          annotation.annotated = target
          annotation.annotator = bot
          annotation.annotation_type = 'mt'
          annotation.set_fields = {'mt_translations': translations.to_json}.to_json
          annotation.save!
      end
    end
  end

end
