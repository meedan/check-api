class Bot::Alegre < BotUser
  check_settings

  ::ProjectMedia.class_eval do
    attr_accessor :alegre_similarity_thresholds
  end

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
        self.send_to_image_similarity_index(pm)
        self.send_to_title_similarity_index(pm)
        self.send_to_description_similarity_index(pm)
        self.get_flags(pm)
        self.relate_project_media_to_similar_items(pm)
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Exception for event `#{body['event']}`: #{e.message}")
      self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
    end
    handled
  end

  def self.translate_similar_items(similar_items, relationship_type)
    Hash[similar_items.collect{|k,v| [k, {score: v, relationship_type: relationship_type}]}]
  end

  def self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed)
    self.translate_similar_items(
      suggested_or_confirmed, Relationship.suggested_type
    ).merge(
      self.translate_similar_items(
        confirmed, Relationship.confirmed_type
      )
    )
  end

  def self.get_similar_items(pm)
    if pm.is_text?
      suggested_or_confirmed = self.get_merged_items_with_similar_text(pm, CONFIG['text_similarity_threshold'])
      confirmed = self.get_merged_items_with_similar_text(pm, CONFIG['automatic_text_similarity_threshold'])
      self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed)
    elsif pm.is_image?
      suggested_or_confirmed = self.get_items_with_similar_image(pm, CONFIG['image_similarity_threshold'])
      confirmed = self.get_merged_items_with_similar_image(pm, CONFIG['automatic_image_similarity_threshold'])
      self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed)
    else
      {}
    end
  end

  def self.get_merged_items_with_similar_text(pm, threshold)
    by_title = self.get_items_with_similar_title(pm, threshold)
    by_description = self.get_items_with_similar_description(pm, threshold)
    Hash[(by_title.keys|by_description.keys).collect do |pmid|
      [pmid, [by_title[pmid].to_f, by_description[pmid].to_f].sort.last]
    end]
  end

  def self.relate_project_media_to_similar_items(pm)
    self.add_relationships(
      pm,
      Bot::Alegre.get_similar_items(pm)
    )
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
    self.save_annotation(pm, 'language', { language: lang })
  end

  def self.save_annotation(pm, type, fields)
    annotation = Dynamic.new
    annotation.annotated = pm
    annotation.annotator = BotUser.alegre_user
    annotation.annotation_type = type
    annotation.disable_es_callbacks = Rails.env.to_s == 'test'
    annotation.set_fields = fields.to_json
    annotation.skip_check_ability = true
    annotation.save!
    annotation
  end

  def self.get_flags(pm, attempts = 0)
    return if pm.report_type != 'uploadedimage'

    begin
      result = self.request_api('get', '/image/classification/', { uri: self.media_file_url(pm) })
      self.save_annotation(pm, 'flag', result['result'])
    rescue
      sleep 1
      self.get_flags(pm, attempts + 1) if attempts < 5
    end
  end

  def self.media_file_url(pm)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    ENV['RAILS_ENV'] != 'development' ? pm.media.file.file.public_url : "#{CONFIG['storage']['endpoint']}/#{CONFIG['storage']['bucket']}/#{pm.media.file.file.path}"
  end

  def self.send_to_title_similarity_index(pm)
    return if pm.title.blank?
    self.send_to_text_similarity_index(pm, 'title', pm.title)
  end

  def self.send_to_description_similarity_index(pm)
    return if pm.description.blank?
    self.send_to_text_similarity_index(pm, 'description', pm.description)
  end

  def self.send_to_text_similarity_index(pm, field, text)
    self.request_api('post', '/text/similarity/', {
      text: text,
      context: {
        team_id: pm.team_id,
        field: field,
        project_media_id: pm.id
      }
    })
  end

  def self.send_to_image_similarity_index(pm)
    return if pm.report_type != 'uploadedimage'
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
      puts response.body
      parsed = JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Alegre error: #{e.message}")
      self.notify_error(e, { bot: self.name, url: uri, params: params }, RequestStore[:request] )
      { 'type' => 'error', 'data' => { 'message' => e.message } }
    end
  end

  def self.get_items_with_similar_title(pm, threshold, text_length_threshold=CONFIG["similarity_text_length_threshold"])
    pm.title.to_s.split(/\s/).length > text_length_threshold ? self.get_items_with_similar_text(pm, 'title', threshold, pm.title) : {}
  end

  def self.get_items_with_similar_description(pm, threshold, text_length_threshold=CONFIG["similarity_text_length_threshold"])
    pm.description.to_s.split(/\s/).length > text_length_threshold ? self.get_items_with_similar_text(pm, 'description', threshold, pm.description) : {}
  end

  def self.extract_project_medias_from_context(search_result)
    # We currently have two cases of context:
    # - a straight hash with project_media_id
    # - an array of hashes, each with project_media_id
    context = self.get_context_from_image_or_text_response(search_result)
    pms = []
    if context.kind_of?(Array)
      context.each{ |c| pms.push(c.with_indifferent_access.dig('project_media_id')) }
    elsif context.kind_of?(Hash)
      pms.push(context.with_indifferent_access.dig('project_media_id'))
    end
    Hash[pms.flatten.collect{|pm| [pm.to_i, self.get_score_from_image_or_text_response(search_result)]}]
  end

  def self.get_context_from_image_or_text_response(search_result)
    search_result.dig('_source', 'context') || search_result.dig('context')
  end

  def self.get_score_from_image_or_text_response(search_result)
    (search_result.with_indifferent_access.dig('_score')||search_result.with_indifferent_access.dig('score'))
  end

  def self.get_similar_items_from_api(path, conditions, pm)
    response = {}
    self.request_api('get', path, conditions).dig('result')&.collect{ |r|
        self.extract_project_medias_from_context(r) 
    }.each do |request_response|
      request_response.each do |pmid, score|
        response[pmid] = score
      end
    end
    response.reject{ |id, score| 
      id.blank? || pm.id == id
    }
  end

  def self.get_items_with_similar_text(pm, field, threshold, text)
    self.get_similar_items_from_api('/text/similarity/', {
      text: text,
      context: {
        team_id: pm.team_id,
        field: field
      },
      threshold: threshold
    }, pm)
  end

  def self.get_items_with_similar_image(pm, threshold)
    self.get_similar_items_from_api('/image/similarity/', {
      url: self.media_file_url(pm),
      context: {
        team_id: pm.team_id,
      },
      threshold: threshold
    }, pm)
  end

  def self.add_relationships(pm, pm_id_scores)
    return if pm_id_scores.blank? || pm_id_scores.keys.include?(pm.id)

    # Take first match as being the best potential parent.
    # Conditions to check for a valid parent in 2-level hierarchy:
    # - If it's a child, get its parent.
    # - If it's a parent, use it.
    # - If it has no existing relationship, use it.
    parent_id = pm_id_scores.keys.sort[0]
    source_ids = Relationship.where(:target_id => parent_id).select(:source_id).distinct
    if source_ids.length > 0
      # Sanity check: if there are multiple parents, something is wrong in the dataset.
      Rails.logger.error("[Alegre Bot] Found multiple relationship parents for ProjectMedia #{parent_id}") if source_ids.length > 1
      # Take the first source as the parent.
      parent_id = source_ids[0].source_id
    end

    # Better be safe than sorry.
    return if parent_id == pm.id
    self.add_relationship(pm, pm_id_scores, parent_id)
  end

  def self.add_relationship(pm, pm_id_scores, parent_id)
    if pm_id_scores[parent_id]
      r = Relationship.new
      r.skip_check_ability = true
      r.relationship_type = pm_id_scores[parent_id][:relationship_type]
      r.weight = pm_id_scores[parent_id][:score]
      r.source_id = parent_id
      r.target_id = pm.id
      r.user_id ||= BotUser.alegre_user&.id
      r.save!
    else
      return false
    end
  end
end
