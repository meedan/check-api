class Bot::Alegre < ActiveRecord::Base

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name

  def self.run(body)
    begin
      data = JSON.parse(body)
      pm = ProjectMedia.where(id: data['data']['dbid']).last
      unless data['event'] != 'create_project_media' or pm.nil? or pm.text.blank? or CONFIG['alegre_host'].blank? or CONFIG['alegre_token'].blank?
        Bot::Alegre.default.get_language_from_alegre(pm)
        Bot::Alegre.default.create_empty_mt_annotation(pm)
        Bot::Alegre.default.create_similarities_from_alegre(pm)
      end
      true
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Error for event #{data['event']}: #{e.message}")
      Airbrake.notify(e) if Airbrake.configuration.api_key
      false
    end
  end

  def self.default
    Bot::Alegre.where(name: 'Alegre Bot').last || Bot::Alegre.new
  end

  def profile_image
    CONFIG['checkdesk_base_url'] + self.avatar.url
  end

  def get_language_from_alegre(target)
    lang = self.get_language_from_alegre_for_text(target.text)
    self.save_language(target, lang) unless lang.nil?
    lang
  end

  def get_language_from_alegre_for_text(text)
    lang = nil
    begin
      response = AlegreClient::Request.get_languages_identification(CONFIG['alegre_host'], { text: text }, CONFIG['alegre_token'])
      lang = response['data'][0][0].split(',').first.downcase if response['type'] == 'language'
    rescue
      lang = nil
    end
    lang
  end

  def get_source_language(target)
    field = self.get_dynamic_field_value(target, 'language', 'language')
    field.nil? ? Bot::Alegre.default.get_language_from_alegre(target) : field.value
  end

  def get_mt_from_alegre(target, author)
    translations = []
    src_lang = self.get_source_language(target)
    languages = target.project.languages - [src_lang]
    languages.each do |lang|
      begin
        response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: target.text, from: src_lang, to: lang }, CONFIG['alegre_token'])
        mt_text = response['data'] if response['type'] == 'mt' && !response['data'].blank?
      rescue
        mt_text = nil
      end
      translations << { lang: lang, text: mt_text } unless mt_text.nil?
    end
    self.update_machine_translation(target, translations, author) unless translations.blank?
    translations
  end

  # Get existing claims which are similar to this new one, in the context of the same project.
  # Find the "parent" claim among the set, and link this new one to it as a "child".
  # If there's no existing parent, create the first relationship now.
  # Then add this new claim to the similarity index.
  def create_similarities_from_alegre(target)
    return if target.media.type != 'Claim'

    src_lang = self.get_source_language(target)
    response = Bot::Alegre.request_api('POST', '/similarity/query', {
      text: target.text,
      language: src_lang,
      context: {
        project_id: target.project.id
      }
    })

    if response['result'] and response['result'].length > 0 then
      pm_ids = response['result'].collect{|r| r.dig('_source', 'context', 'project_media_id')}
      return if pm_ids.include?(target.id)

      # Take first match as being the best potential parent.
      # Conditions to check for a valid parent in 2-level hierarchy:
      # - If it's a child, get its parent.
      # - If it's a parent, use it.
      # - If it has no existing relationship, use it.
      parent_id = pm_ids[0]
      source_ids = Relationship.where(:target_id => parent_id).select(:source_id).distinct
      if source_ids.length > 0 then
        # Sanity check: if there are multiple parents, something is wrong in the dataset.
        if source_ids.length > 1 then
          Rails.logger.error("[Alegre Bot] Found multiple relationship parents for ProjectMedia #{parent_id}")
        end
        # Take the first source as the parent.
        parent_id = source_ids[0].source_id
      end

      # Better be safe than sorry.
      return if parent_id == target.id

      r = Relationship.new
      r.skip_check_ability = true
      r.relationship_type = { source: 'parent', target: 'child' }
      r.source_id = parent_id
      r.target_id = target.id
      r.save!
    end

    Bot::Alegre.request_api('POST', '/similarity/', {
      text: target.text,
      language: src_lang,
      context: {
        team_id: target.project.team.id,
        project_id: target.project.id,
        project_media_id: target.id
      }
    })
  end

  def language_object(target, attr = nil)
    field = self.get_dynamic_field_value(target, 'language', 'language')
    return nil if field.nil?
    attr.nil? ? field : field.send(attr)
  end

  def get_dynamic_field_value(target, annotation_type, field_type)
    DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => annotation_type, 'annotations.annotated_type' => target.class.name, 'annotations.annotated_id' => target.id.to_s, field_type: field_type).first
  end

  def create_empty_mt_annotation(target)
    src_lang = self.language_object(target, :value)
    languages = target.project.get_languages
    unless src_lang.blank? or languages.nil?
      annotation = Dynamic.new
      annotation.annotated = target
      annotation.annotator = self
      annotation.annotation_type = 'mt'
      annotation.set_fields = { 'mt_translations': [].to_json }.to_json
      annotation.skip_notifications = true
      annotation.disable_es_callbacks = Rails.env.to_s == 'test'
      annotation.save!
      annotation.update_columns(annotator_id: self.id, annotator_type: 'Bot::Alegre')
    end
  end

  protected

  def self.request_api(method, path, params = {})
    uri = URI(CONFIG['alegre_host'] + path)
    klass = 'Net::HTTP::' + method.capitalize
    request = klass.constantize.new(uri.path, 'Content-Type' => 'application/json')
    request.body = params.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = uri.scheme == 'https'
    begin
      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      { 'type' => 'error', 'data' => { 'message' => e.message } }
    end
  end

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
      mt.set_fields = { 'mt_translations': translations.to_json }.to_json
      mt.disable_es_callbacks = Rails.env.to_s == 'test'
      mt.save!
      User.current = nil
      # Delete old versions
      mt_field = self.get_dynamic_field_value(target, 'mt', 'json')
      versions = mt_field.versions.to_a unless mt_field.nil?
      unless versions.blank?
        versions.pop
        versions.each{ |v| v.skip_check_ability = true; v.destroy }
      end
    end
  end
end
