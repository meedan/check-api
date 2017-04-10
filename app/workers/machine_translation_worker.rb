class MachineTranslationWorker
  include Sidekiq::Worker

  def perform(target, bot)
    target = YAML::load(target)
    bot = YAML::load(bot)
    field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'language', 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: 'language').first
    unless field.nil?
      src_lang = field.value
      text = target.text
      # TODO: replace languages with `User.settings.languages`
      languages = ['ar']
      languages.each do |lang|
        begin
          response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: text, from: src_lang, to: lang }, CONFIG['alegre_token'])
          mt_text = response['data']
        rescue
          mt_text = nil
        end
        unless mt_text.nil?
          annotation = Dynamic.new
          annotation.annotated = target
          annotation.annotator = bot
          annotation.annotation_type = 'mt'
          annotation.set_fields = {'mt_text': mt_text}.to_json
          annotation.save!
        end
      end
    end
  end

end
