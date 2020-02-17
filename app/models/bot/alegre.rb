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
      self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
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
    annotation.skip_check_ability = true
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
      team_id: pm.team_id,
      project_id: pm.project_id,
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
    context = self.get_context(pm).to_json
    Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') do |http|
      req = Net::HTTP::Post::Multipart.new(url, {
        'url' => pm.media.file.file.public_url,
        'context' => context,
        'filter' => { project_id: pm.project.id }.to_json,
        'threshold' => 1,
        'limit' => 1
      })

      begin
        response = JSON.parse(http.request(req).body)
      rescue StandardError => e
        Rails.logger.error("[Alegre Bot] Bad response from VFRAME: #{e.message}")
        self.class.notify_error(e, { bot_id: self.id, vframe_url: url, context: context }, RequestStore[:request] )
      end
    end
    pm_ids = response.dig('results')&.collect{|r| r.dig('context', 'project_media_id')}
    self.add_relationships(pm, pm_ids)
  end
end
