class Bot::Alegre < BotUser
  check_settings
  MEAN_TOKENS_MODEL = "xlm-r-bert-base-nli-stsb-mean-tokens"
  INDIAN_MODEL = "indian-sbert"
  ELASTICSEARCH_MODEL = "elasticsearch"

  ::ProjectMedia.class_eval do
    attr_accessor :alegre_similarity_thresholds
  end

  DynamicAnnotation::Field.class_eval do
    after_commit :save_analysis_to_similarity_index, if: :can_be_sent_to_index?, on: [:create, :update]
    after_destroy :delete_analysis_from_similarity_index, if: :can_be_sent_to_index?
    
    def self.save_analysis_to_similarity_index(pm_id)
      pm = ProjectMedia.find_by_id(pm_id)
      Bot::Alegre.send_title_to_similarity_index(pm, 'analysis_title')
      Bot::Alegre.send_description_to_similarity_index(pm, 'analysis_description')
    end

    def self.delete_analysis_from_similarity_index(pm_id)
      pm = ProjectMedia.find_by_id(pm_id)
      Bot::Alegre.delete_field_from_text_similarity_index(pm, 'analysis_title')
      Bot::Alegre.delete_field_from_text_similarity_index(pm, 'analysis_description')
    end

    private

    def can_be_sent_to_index?
      ['content', 'title'].include?(self.field_name) &&
      self.annotation.annotation_type == 'verification_status' &&
      Bot::Alegre.team_has_alegre_bot_installed?(self.annotation&.annotated&.team&.id&.to_i)
    end

    def save_analysis_to_similarity_index
      self.class.delay.save_analysis_to_similarity_index(self.annotation.annotated_id)
    end

    def delete_analysis_from_similarity_index
      self.class.delay.delete_analysis_from_similarity_index(self.annotation.annotated_id)
    end
  end

  def self.default_model
    CheckConfig.get('alegre_default_model') || Bot::Alegre::ELASTICSEARCH_MODEL
  end

  def self.default_matching_model
    Bot::Alegre::ELASTICSEARCH_MODEL
  end

  def self.run(body)
    if CheckConfig.get('alegre_host').blank?
      Rails.logger.warn("[Alegre Bot] Skipping events because `alegre_host` config is blank")
      return false
    end

    handled = false
    pm = nil
    begin
      pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
      if body.dig(:event) == 'create_project_media' && !pm.nil?
        self.get_language(pm)
        self.send_to_image_similarity_index(pm)
        self.send_title_to_similarity_index(pm, 'original_title')
        self.send_description_to_similarity_index(pm, 'original_description')
        self.get_flags(pm)
        self.relate_project_media_to_similar_items(pm)
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Exception for event `#{body['event']}`: #{e.message}")
      self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
    end

    self.unarchive_if_archived(pm)

    handled
  end

  def self.unarchive_if_archived(pm)
    if pm&.archived == CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS
      pm.update_column(:archived, CheckArchivedFlags::FlagCodes::NONE)
      sources_count = Relationship.where(target_id: pm.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
      pm.update_elasticsearch_doc(['archived', 'sources_count'], { 'archived' => CheckArchivedFlags::FlagCodes::NONE, 'sources_count' => sources_count }, pm)
    end
  end

  def self.translate_similar_items(similar_items, relationship_type)
    Hash[similar_items.collect{|k,v| [k, {score: v, relationship_type: relationship_type}]}]
  end

  def self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
    suggested_or_confirmed_results = self.translate_similar_items(
      suggested_or_confirmed, Relationship.suggested_type
    )
    if pm.is_link?
      suggested_or_confirmed_results
    else
      suggested_or_confirmed_results.merge(
        self.translate_similar_items(
          confirmed, Relationship.confirmed_type
        )
      )
    end
  end

  def self.get_threshold_for_text_query(pm, automatic=false)
    model = self.matching_model_to_use(pm)
    key = "text_similarity_threshold"
    key = "automatic_#{key}" if automatic
    key = "vector_#{key}" if model != Bot::Alegre::ELASTICSEARCH_MODEL
    return CheckConfig.get(key).to_f
  end  

  def self.get_similar_items(pm)
    if pm.is_text?
      suggested_or_confirmed = self.get_merged_items_with_similar_text(pm, self.get_threshold_for_text_query(pm))
      confirmed = self.get_merged_items_with_similar_text(pm, self.get_threshold_for_text_query(pm, true))
      self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
    elsif pm.is_image?
      suggested_or_confirmed = self.get_items_with_similar_image(pm, CheckConfig.get('image_similarity_threshold').to_f)
      confirmed = self.get_items_with_similar_image(pm, CheckConfig.get('automatic_image_similarity_threshold').to_f)
      self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
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
      lang = response['result']['language'] || lang
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
    ENV['RAILS_ENV'] != 'development' ? pm.media.file.file.public_url : "#{CheckConfig.get('storage_endpoint')}/#{CheckConfig.get('storage_bucket')}/#{pm.media.file.file.path}"
  end

  def self.item_doc_id(object, field_name)
    Base64.encode64(["check", object.class.to_s.underscore, object.id, field_name].join("-")).strip.delete("\n").delete("=")
  end

  def self.send_title_to_similarity_index(pm, field)
    return if pm.title.blank?
    self.send_to_text_similarity_index(pm, field, pm.title, self.item_doc_id(pm, field))
  end

  def self.send_description_to_similarity_index(pm, field)
    return if pm.description.blank?
    self.send_to_text_similarity_index(pm, field, pm.description, self.item_doc_id(pm, field))
  end

  def self.team_has_alegre_bot_installed?(team_id)
    bot = BotUser.alegre_user
    tbi = TeamBotInstallation.find_by_team_id_and_user_id team_id, bot&&bot.id
    !tbi.nil?
  end

  def self.indexing_model_to_use(pm)
    bot = BotUser.alegre_user
    tbi = TeamBotInstallation.find_by_team_id_and_user_id pm.team_id, bot&&bot.id
    return self.default_model if tbi.nil?
    tbi.get_alegre_model_in_use || self.default_model
  end

  def self.matching_model_to_use(pm)
    bot = BotUser.alegre_user
    tbi = TeamBotInstallation.find_by_team_id_and_user_id pm.team_id, bot&&bot.id
    return self.default_matching_model if tbi.nil?
    tbi.get_alegre_matching_model_in_use || self.default_matching_model
  end

  def self.delete_field_from_text_similarity_index(pm, field)
    self.delete_from_text_similarity_index(self.item_doc_id(pm, field))
  end

  def self.delete_from_text_similarity_index(doc_id)
    self.request_api('delete', '/text/similarity/', {
      doc_id: doc_id
    })
  end

  def self.send_to_text_similarity_index_package(pm, field, text, doc_id, model=nil)
    model ||= self.indexing_model_to_use(pm)
    {
      doc_id: doc_id,
      text: text,
      model: model,
      context: {
        team_id: pm.team_id,
        field: field,
        project_media_id: pm.id,
        has_custom_id: true
      }
    }
  end

  def self.send_to_text_similarity_index(pm, field, text, doc_id, model=nil)
    self.request_api(
      'post',
      '/text/similarity/',
      self.send_to_text_similarity_index_package(pm, field, text, doc_id, model)
    )
  end

  def self.send_to_image_similarity_index_package(pm)
    {
      doc_id: self.item_doc_id(pm, 'image'),
      url: self.media_file_url(pm),
      context: {
        team_id: pm.team_id,
        project_media_id: pm.id,
        has_custom_id: true
      }
    }
  end

  def self.send_to_image_similarity_index(pm)
    return if pm.report_type != 'uploadedimage'
    self.request_api(
      'post',
      '/image/similarity/',
      self.send_to_image_similarity_index_package(pm)
    )
  end

  def self.request_api(method, path, params = {})
    uri = URI(CheckConfig.get('alegre_host') + path)
    klass = 'Net::HTTP::' + method.capitalize
    request = klass.constantize.new(uri.path, 'Content-Type' => 'application/json')
    request.body = params.to_json
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = uri.scheme == 'https'
    begin
      response = http.request(request)
      parsed = JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Alegre error: #{e.message}")
      self.notify_error(e, { bot: self.name, url: uri, params: params }, RequestStore[:request] )
      { 'type' => 'error', 'data' => { 'message' => e.message } }
    end
  end

  def self.similarity_text_length_threshold
    CheckConfig.get("similarity_text_length_threshold").to_f
  end

  def self.get_items_with_similar_title(pm, threshold, text_length_threshold=self.similarity_text_length_threshold)
    pm.title.to_s.split(/\s/).length > text_length_threshold ? self.get_merged_similar_items(pm, threshold, ['original_title', 'analysis_title'], pm.title) : {}
  end

  def self.get_items_with_similar_description(pm, threshold, text_length_threshold=self.similarity_text_length_threshold)
    pm.description.to_s.split(/\s/).length > text_length_threshold ? self.get_merged_similar_items(pm, threshold, ['original_description', 'analysis_description'], pm.description) : {}
  end

  def self.get_merged_similar_items(pm, threshold, fields, value)
    es_matches = fields.collect{|field| self.get_items_with_similar_text(pm, field, threshold, value, self.default_matching_model)}.reduce({}, :merge)
    if self.matching_model_to_use(pm) == self.default_matching_model
      es_matches
    else
      fields.collect{|field| self.get_items_with_similar_text(pm, field, threshold, value)}.reduce({}, :merge).merge(
        es_matches
      )
    end
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
    Hash[pms.flatten.collect{ |pm| [pm.to_i, self.get_score_from_image_or_text_response(search_result)] }]
  end

  def self.get_context_from_image_or_text_response(search_result)
    search_result.dig('_source', 'context') || search_result.dig('context')
  end

  def self.get_score_from_image_or_text_response(search_result)
    (search_result.with_indifferent_access.dig('_score')||search_result.with_indifferent_access.dig('score'))
  end

  def self.get_similar_items_from_api(path, conditions)
    response = {}
    result = self.request_api('get', path, conditions).dig('result')
    project_medias = result.collect{ |r| self.extract_project_medias_from_context(r) } unless result.nil?
    project_medias.each do |request_response|
      request_response.each do |pmid, score|
        response[pmid] = score
      end
    end unless project_medias.nil?
    response.reject{ |id, _score| id.blank? }
  end

  def self.get_items_with_similar_text(pm, field, threshold, text, model = nil)
    model ||= self.matching_model_to_use(pm)
    self.get_items_from_similar_text(pm.team_id, text, field, threshold, model).reject{ |id, _score| pm.id == id }
  end

  def self.get_items_from_similar_text(team_id, text, field = nil, threshold = nil, model = nil, fuzzy = false)
    field ||= ['original_title', 'original_description', 'analysis_title', 'analysis_description']
    threshold ||= self.get_threshold_for_text_query(pm, true)
    model ||= self.matching_model_to_use(ProjectMedia.new(team_id: team_id))
    self.get_similar_items_from_api('/text/similarity/', {
      text: text,
      model: model,
      fuzzy: fuzzy == 'true' || fuzzy.to_i == 1,
      context: {
        team_id: team_id,
        field: field,
        has_custom_id: true
      },
      threshold: threshold
    })
  end

  def self.get_items_with_similar_image(pm, threshold)
    self.get_items_from_similar_image(pm.team_id, self.media_file_url(pm), threshold).reject{ |id, _score| pm.id == id }
  end

  def self.get_items_from_similar_image(team_id, image_url, threshold)
    self.get_similar_items_from_api('/image/similarity/', {
      url: image_url,
      context: {
        team_id: team_id,
        has_custom_id: true
      },
      threshold: threshold
    })
  end

  def self.add_relationships(pm, pm_id_scores)
    return if pm_id_scores.blank? || pm_id_scores.keys.include?(pm.id)

    # Take first match as being the best potential parent.
    # Conditions to check for a valid parent in 2-level hierarchy:
    # - If it's a child, get its parent.
    # - If it's a parent, use it.
    # - If it has no existing relationship, use it.

    parent_id = pm_id_scores.keys.sort[0]
    parent_relationships = Relationship.where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).where(target_id: parent_id).all
    if parent_relationships.length > 0
      # Sanity check: if there are multiple parents, something is wrong in the dataset.
      self.notify_error(StandardError.new("[Alegre Bot] Found multiple similarity relationship parents for ProjectMedia #{parent_id}"), {}, RequestStore[:request]) if parent_relationships.length > 1
      # Take the first source as the parent (A).
      # 1. A is confirmed to B and C is suggested to B: type of the relationship between A and C is: suggested
      # 2. A is confirmed to B and C is confirmed to B: type of the relationship between A and C is: confirmed
      # 3. A is suggested to B and C is suggested to B: type of the relationship between A and C is: suggested
      # 4. A is suggested to B and C is confirmed to B: type of the relationship between A and C is: suggested
      parent_relationship = parent_relationships.first
      new_type = Relationship.suggested_type
      if parent_relationship.is_confirmed? && pm_id_scores[parent_id][:relationship_type] == Relationship.confirmed_type
        new_type = Relationship.confirmed_type
      end
      parent_id = parent_relationship.source_id
      pm_id_scores[parent_id][:relationship_type] = new_type if pm_id_scores[parent_id]
    end

    # Better be safe than sorry.
    return if parent_id == pm.id
    self.add_relationship(pm, pm_id_scores, parent_id)
  end

  def self.add_relationship(pm, pm_id_scores, parent_id)
    parent = ProjectMedia.find_by_id(parent_id)
    return false if parent.nil?
    if parent.is_blank?
      parent.replace_by(pm)
    elsif pm_id_scores[parent_id]
      r = Relationship.new
      r.skip_check_ability = true
      r.relationship_type = pm_id_scores[parent_id][:relationship_type]
      r.weight = pm_id_scores[parent_id][:score]
      r.source_id = parent_id
      r.target_id = pm.id
      r.user_id ||= BotUser.alegre_user&.id
      r.save!
      CheckNotification::InfoMessages.send(
        r.is_confirmed? ? 'related_to_confirmed_similar' : 'related_to_suggested_similar',
        item_title: pm.title,
        similar_item_title: parent.title
      )
    end
  end
end
