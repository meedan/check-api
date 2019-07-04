class Bot::Alegre < BotUser
  
  check_settings
  
  def self.run(body)
    handled = false
    begin
      pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
      if body.dig(:event) == 'create_project_media' && !pm.nil?
        Bot::Alegre.default.get_language(pm)
        Bot::Alegre.default.get_image_similarities(pm)
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Exception for event #{body['event']}: #{e.message}")
      Airbrake.notify(e) if Airbrake.configuration.api_key
    end
    handled
  end

  def self.default
    Bot::Alegre.new
  end

  def get_language(pm)
    lang = pm.text.blank? || CONFIG['alegre_host'].blank? ? 'und' : self.get_language_from_alegre(pm.text)
    self.save_language(pm, lang)
    lang
  end

  def get_language_from_alegre(text)
    lang = 'und'
    begin
      response = AlegreClient::Request.get_languages_identification(CONFIG['alegre_host'], { text: text }, CONFIG['alegre_token'])
      lang = response['data'][0][0].split(',').first.downcase if response['type'] == 'language'
    rescue
    end
    lang
  end

  def save_language(pm, lang)
    annotation = Dynamic.new
    annotation.annotated = pm
    annotation.annotator = BotUser.where(login: 'alegre').first
    annotation.annotation_type = 'language'
    annotation.disable_es_callbacks = Rails.env.to_s == 'test'
    annotation.set_fields = { language: lang }.to_json
    annotation.save!
    annotation
  end

  def language_object(pm, attr = nil)
    field = self.get_dynamic_field_value(pm, 'language', 'language')
    return nil if field.nil?
    attr.nil? ? field : field.send(attr)
  end

  def get_dynamic_field_value(pm, annotation_type, field_type)
    DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => annotation_type, 'annotations.annotated_type' => pm.class.name, 'annotations.annotated_id' => pm.id.to_s, field_type: field_type).first
  end

  def get_context(pm)
    {
      team_id: pm.project.team.id,
      project_id: pm.project.id,
      project_media_id: pm.id
    }
  end

  def add_relationships(pm, pm_ids)
    return if pm_ids.blank? || pm_ids.include?(pm.id)

    # Take first match as being the best potential parent.
    # Conditions to check for a valid parent in 2-level hierarchy:
    # - If it's a child, get its parent.
    # - If it's a parent, use it.
    # - If it has no existing relationship, use it.
    parent_id = pm_ids[0]
    source_ids = Relationship.where(:target_id => parent_id).select(:source_id).distinct
    if source_ids.length > 0
      # Sanity check: if there are multiple parents, something is wrong in the dataset.
      Rails.logger.error("[Alegre Bot] Found multiple relationship parents for ProjectMedia #{parent_id}") if source_ids.length > 1
      # Take the first source as the parent.
      parent_id = source_ids[0].source_id
    end

    # Better be safe than sorry.
    return if parent_id == pm.id

    r = Relationship.new
    r.skip_check_ability = true
    r.relationship_type = { source: 'parent', target: 'child' }
    r.source_id = parent_id
    r.target_id = pm.id
    r.save!
  end

  def get_image_similarities(pm)
    return if pm.report_type != 'uploadedimage' or CONFIG['vframe_host'].blank?

    require 'net/http/post/multipart'

    # Send image to VFRAME to get matches.
    url = URI.parse(CONFIG['vframe_host'] + '/api/v1/match')
    response = { 'results' => [] }
    Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') do |http|
      req = Net::HTTP::Post::Multipart.new(url, {
        'url' => CONFIG['checkdesk_base_url_private'] + pm.media.file.url,
        'context' => self.get_context(pm).to_json,
        'filter' => { project_id: pm.project.id }.to_json,
        'threshold' => 1,
        'limit' => 1
      })

      begin
        response = JSON.parse(http.request(req).body)
      rescue StandardError => e
        Rails.logger.error("[Alegre Bot] Bad response from VFRAME: #{e.message}")
        Airbrake.notify(e) if Airbrake.configuration.api_key
      end
    end
    pm_ids = response.dig('results')&.collect{|r| r.dig('context', 'project_media_id')}
    self.add_relationships(pm, pm_ids)
  end

  # def get_source_language(pm)
  #   field = self.get_dynamic_field_value(pm, 'language', 'language')
  #   field.nil? ? Bot::Alegre.default.get_language_from_alegre(pm) : field.value
  # end

  # def get_mt_from_alegre(pm, author)
  #   translations = []
  #   src_lang = self.get_source_language(pm)
  #   languages = pm.project.languages - [src_lang]
  #   languages.each do |lang|
  #     begin
  #       response = AlegreClient::Request.get_mt(CONFIG['alegre_host'], { text: pm.text, from: src_lang, to: lang }, CONFIG['alegre_token'])
  #       mt_text = response['data'] if response['type'] == 'mt' && !response['data'].blank?
  #     rescue
  #       mt_text = nil
  #     end
  #     translations << { lang: lang, text: mt_text } unless mt_text.nil?
  #   end
  #   self.update_machine_translation(pm, translations, author) unless translations.blank?
  #   translations
  # end

  # Get existing claims which are similar to this new one, in the context of the same project.
  # Find the "parent" claim among the set, and link this new one to it as a "child".
  # If there's no existing parent, create the first relationship now.
  # Then add this new claim to the similarity index.
  # def create_similarities_from_alegre(pm)
  #   return if pm.media.type != 'Claim'

  #   src_lang = self.get_source_language(pm)
  #   response = Bot::Alegre.request_api('POST', '/similarity/query', {
  #     text: pm.text,
  #     language: src_lang,
  #     context: {
  #       project_id: pm.project.id
  #     }
  #   })

  #   if response['result'] and response['result'].length > 0 then
  #     pm_ids = response['result'].collect{|r| r.dig('_source', 'context', 'project_media_id')}
  #     return if pm_ids.include?(pm.id)

  #     # Take first match as being the best potential parent.
  #     # Conditions to check for a valid parent in 2-level hierarchy:
  #     # - If it's a child, get its parent.
  #     # - If it's a parent, use it.
  #     # - If it has no existing relationship, use it.
  #     parent_id = pm_ids[0]
  #     source_ids = Relationship.where(:pm_id => parent_id).select(:source_id).distinct
  #     if source_ids.length > 0 then
  #       # Sanity check: if there are multiple parents, something is wrong in the dataset.
  #       if source_ids.length > 1 then
  #         Rails.logger.error("[Alegre Bot] Found multiple relationship parents for ProjectMedia #{parent_id}")
  #       end
  #       # Take the first source as the parent.
  #       parent_id = source_ids[0].source_id
  #     end

  #     # Better be safe than sorry.
  #     return if parent_id == pm.id

  #     r = Relationship.new
  #     r.skip_check_ability = true
  #     r.relationship_type = { source: 'parent', pm: 'child' }
  #     r.source_id = parent_id
  #     r.pm_id = pm.id
  #     r.save!
  #   end

  #   Bot::Alegre.request_api('POST', '/similarity/', {
  #     text: pm.text,
  #     language: src_lang,
  #     context: {
  #       team_id: pm.project.team.id,
  #       project_id: pm.project.id,
  #       project_media_id: pm.id
  #     }
  #   })
  # end

  # def create_empty_mt_annotation(pm)
  #   src_lang = self.language_object(pm, :value)
  #   languages = pm.project.get_languages
  #   unless src_lang.blank? or languages.nil?
  #     annotation = Dynamic.new
  #     annotation.annotated = pm
  #     annotation.annotator = self
  #     annotation.annotation_type = 'mt'
  #     annotation.set_fields = { 'mt_translations': [].to_json }.to_json
  #     annotation.skip_notifications = true
  #     annotation.disable_es_callbacks = Rails.env.to_s == 'test'
  #     annotation.save!
  #   end
  # end

  # def self.request_api(method, path, params = {})
  #   uri = URI(CONFIG['alegre_host'] + path)
  #   klass = 'Net::HTTP::' + method.capitalize
  #   request = klass.constantize.new(uri.path, 'Content-Type' => 'application/json')
  #   request.body = params.to_json
  #   http = Net::HTTP.new(uri.hostname, uri.port)
  #   http.use_ssl = uri.scheme == 'https'
  #   begin
  #     response = http.request(request)
  #     JSON.parse(response.body)
  #   rescue StandardError => e
  #     { 'type' => 'error', 'data' => { 'message' => e.message } }
  #   end
  # end

  # def update_machine_translation(pm, translations, author)
  #   mt = pm.annotations.where(annotation_type: 'mt').last
  #   unless mt.nil?
  #     mt = mt.load
  #     User.current = author
  #     mt.set_fields = { 'mt_translations': translations.to_json }.to_json
  #     mt.disable_es_callbacks = Rails.env.to_s == 'test'
  #     mt.save!
  #     User.current = nil
  #     # Delete old versions
  #     mt_field = self.get_dynamic_field_value(pm, 'mt', 'json')
  #     versions = mt_field.versions.to_a unless mt_field.nil?
  #     unless versions.blank?
  #       versions.pop
  #       versions.each{ |v| v.skip_check_ability = true; v.destroy }
  #     end
  #   end
  # end
end
