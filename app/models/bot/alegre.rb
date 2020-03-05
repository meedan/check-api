class Bot::Alegre < BotUser

  check_settings

  def self.run(body)
    if CONFIG['alegre_host'].blank?
      Rails.logger.warn("[Alegre Bot] Skipping events because `alegre_host` config is blank")
      return false
    end

    handled = false
    begin
      pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
      if body.dig(:event) == 'create_project_media' && !pm.nil?
        self.get_language(pm)
        self.get_image_similarities(pm)
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Exception for event `#{body['event']}`: #{e.message}")
      self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
    end
    handled
  end

  def self.get_language(pm)
    lang = pm.text.blank? ? 'und' : self.get_language_from_alegre(pm.text)
    self.save_language(pm, lang)
    lang
  end

  def self.get_language_from_alegre(text)
    lang = 'und'
    begin
      response = self.request_api('get', '/text/langid/', { text: text })
      lang = response['result']['language']
    rescue
    end
    lang
  end

  def self.save_language(pm, lang)
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

  def self.add_relationships(pm, pm_ids)
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

  def self.media_file_url(pm)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    ENV['RAILS_ENV'] != 'development' ? pm.media.file.file.public_url : "#{CONFIG['storage']['endpoint']}/#{CONFIG['storage']['bucket']}/#{pm.media.file.file.path}"
  end

  def self.get_image_similarities(pm)
    return if pm.report_type != 'uploadedimage'

    # Query for similar images.
    similar = self.request_api('get', '/image/similarity/', {
      url: self.media_file_url(pm),
      context: {
        team_id: pm.team_id,
      },
      threshold: 5 # TODO This will eventually change to a user-selectable threshold
    })
    pm_ids = similar.dig('result')&.collect{|r| r.dig('context', 'project_media_id')}
    self.add_relationships(pm, pm_ids)

    # Add image to similarity database.
    self.request_api('post', '/image/similarity/', {
      url: self.media_file_url(pm),
      context: {
        team_id: pm.team_id,
        project_media_id: pm.id
      }
    })
  end

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
      Rails.logger.error("[Alegre Bot] Alegre error: #{e.message}")
      self.class.notify_error(e, { bot: self.name, url: uri, params: params }, RequestStore[:request] )
      { 'type' => 'error', 'data' => { 'message' => e.message } }
    end
  end

end
