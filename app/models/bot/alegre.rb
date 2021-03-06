class Bot::Alegre < BotUser
  check_settings

  # Text similarity models
  MEAN_TOKENS_MODEL = 'xlm-r-bert-base-nli-stsb-mean-tokens'
  INDIAN_MODEL = 'indian-sbert'
  ELASTICSEARCH_MODEL = 'elasticsearch'

  REPORT_TEXT_SIMILARITY_FIELDS = ['report_text_title', 'report_text_content', 'report_visual_card_title', 'report_visual_card_content']

  ::ProjectMedia.class_eval do
    attr_accessor :alegre_similarity_thresholds, :alegre_matched_fields
  end

  Dynamic.class_eval do
    after_commit :send_annotation_data_to_similarity_index, if: :can_be_sent_to_index?, on: [:create, :update]
    after_create :match_similar_items_using_ocr

    def self.send_annotation_data_to_similarity_index(pm_id, annotation_type)
      pm = ProjectMedia.find_by_id(pm_id)
      if annotation_type == 'report_design'
        REPORT_TEXT_SIMILARITY_FIELDS.each do |field|
          Bot::Alegre.send_field_to_similarity_index(pm, field)
        end
      elsif annotation_type == 'extracted_text'
        Bot::Alegre.send_field_to_similarity_index(pm, 'extracted_text')
      end
    end

    def self.match_similar_items_using_ocr(id)
      annotation = Dynamic.find(id)
      if annotation.annotation_type == 'extracted_text'
        pm = annotation.annotated
        text = annotation.get_field_value('text')
        return if text.blank? || !Bot::Alegre.should_get_similar_items_of_type?('master', pm.team_id) || !Bot::Alegre.should_get_similar_items_of_type?('image', pm.team_id)
        matches = Bot::Alegre.get_items_with_similar_description(pm, Bot::Alegre.get_threshold_for_query('text', pm), text).max_by{ |_pm_id, score| score }
        unless matches.nil?
          match_id, score = matches
          match = ProjectMedia.find_by_id(match_id)
          return if match.nil?
          parent = Relationship.confirmed_parent(match)
          Bot::Alegre.create_relationship(parent, pm, score, Relationship.suggested_type)
        end
      end
    end

    private

    def can_be_sent_to_index?
      ['report_design', 'extracted_text'].include?(self.annotation_type) &&
      Bot::Alegre.team_has_alegre_bot_installed?(self.annotated&.team&.id&.to_i)
    end

    def send_annotation_data_to_similarity_index
      self.class.delay_for(5.seconds, retry: 5).send_annotation_data_to_similarity_index(self.annotated_id, self.annotation_type)
    end

    def match_similar_items_using_ocr
      self.class.delay_for(5.seconds, retry: 5).match_similar_items_using_ocr(self.id)
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
        self.send_to_media_similarity_index(pm)
        self.send_field_to_similarity_index(pm, 'original_title')
        self.send_field_to_similarity_index(pm, 'original_description')
        self.get_extracted_text(pm)
        self.relate_project_media_to_similar_items(pm)
        self.get_flags(pm)
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

  def self.restrict_to_same_modality(pm, matches)
    other_pms = Hash[ProjectMedia.where(id: matches.keys).includes(:media).all.collect{ |item| [item.id, item] }]
    pm.is_text? ? matches.select{ |k, _v| other_pms[k.to_i]&.is_text? || !other_pms[k.to_i]&.extracted_text.blank? } : matches.select{ |k, _v| other_pms[k.to_i]&.media&.type == pm.media.type }
  end

  def self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
    suggested_or_confirmed_results = self.translate_similar_items(
      suggested_or_confirmed, Relationship.suggested_type
    )
    if pm.is_link?
      self.restrict_to_same_modality(pm, suggested_or_confirmed_results)
    else
      self.restrict_to_same_modality(
        pm,
        suggested_or_confirmed_results.merge(
          self.translate_similar_items(
            confirmed, Relationship.confirmed_type
          )
        )
      )
    end
  end

  def self.get_threshold_for_query(media_type, pm, automatic = false)
    similarity_method = media_type == 'text' ? 'elasticsearch' : 'hash'
    similarity_level = automatic ? 'matching' : 'suggestion'
    setting_type = 'threshold'
    if media_type == 'text' && !pm.nil?
      model = self.matching_model_to_use(pm)
      similarity_method = 'vector' if model != Bot::Alegre::ELASTICSEARCH_MODEL
    end
    key = "#{media_type}_#{similarity_method}_#{similarity_level}_#{setting_type}"
    tbi = self.get_alegre_tbi(pm&.team_id)
    settings = tbi.alegre_settings unless tbi.nil?
    value = settings.blank? ? CheckConfig.get(key) : settings[key]
    { value: value.to_f, key: key, automatic: automatic }
  end

  def self.should_get_similar_items_of_type?(type, team_id)
    tbi = self.get_alegre_tbi(team_id)
    key = "#{type}_similarity_enabled"
    (!tbi || tbi.send("get_#{key}").nil?) ? (CheckConfig.get(key, true).to_s == 'true') : tbi.send("get_#{key}")
  end

  def self.get_similar_items(pm)
    type = nil
    if pm.is_text?
      type = 'text'
    elsif pm.is_image?
      type = 'image'
    elsif pm.is_video?
      type = 'video'
    elsif pm.is_audio?
      type = 'audio'
    end
    unless type.blank?
      return {} if !self.should_get_similar_items_of_type?('master', pm.team_id) || !self.should_get_similar_items_of_type?(type, pm.team_id)
      suggested_or_confirmed = self.get_items_with_similarity(type, pm, self.get_threshold_for_query(type, pm))
      confirmed = self.get_items_with_similarity(type, pm, self.get_threshold_for_query(type, pm, true))
      self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
    else
      {}
    end
  end

  def self.get_items_with_similarity(type, pm, threshold)
    if type == 'text'
      self.get_merged_items_with_similar_text(pm, threshold)
    else
      self.reject_same_case(self.get_items_with_similar_media(self.media_file_url(pm), threshold, pm.team_id, "/#{type}/similarity/"), pm)
    end
  end

  def self.get_merged_items_with_similar_text(pm, threshold)
    by_title = self.get_items_with_similar_title(pm, threshold)
    by_description = self.get_items_with_similar_description(pm, threshold)
    Hash[(by_title.keys|by_description.keys).collect do |pmid|
      [pmid, [by_title[pmid].to_f, by_description[pmid].to_f].max]
    end]
  end

  def self.relate_project_media_to_similar_items(pm)
    self.add_relationships(pm, self.get_similar_items(pm)) unless pm.is_blank?
  end

  def self.get_language(pm)
    lang = pm.text.blank? ? 'und' : self.get_language_from_alegre(pm.text)
    self.save_language(pm, lang)
    lang
  end

  def self.get_language_from_alegre(text)
    lang = 'und'
    begin
      response = self.request_api('get', '/text/langid/', { text: text }, 'query')
      lang = response['result']['language'] || lang
    rescue
      nil
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

  def self.get_flags(pm)
    if pm.report_type == 'uploadedimage'
      result = self.request_api('get', '/image/classification/', { uri: self.media_file_url(pm) }, 'query')
      self.save_annotation(pm, 'flag', result['result'])
    end
  end

  def self.get_extracted_text(pm)
    if pm.report_type == 'uploadedimage'
      result = self.request_api('get', '/image/ocr/', { url: self.media_file_url(pm) }, 'query')
      self.save_annotation(pm, 'extracted_text', result) if result
    end
  end

  def self.media_file_url(pm)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    ENV['RAILS_ENV'] != 'development' ? pm.media.file.file.public_url : "#{CheckConfig.get('storage_endpoint')}/#{CheckConfig.get('storage_bucket')}/#{pm.media.file.file.path}"
  end

  def self.item_doc_id(object, field_name)
    Base64.encode64(["check", object.class.to_s.underscore, object.id, field_name].join("-")).strip.delete("\n").delete("=")
  end

  def self.decode_item_doc_id(doc_id)
    Base64.decode64(doc_id).split("-")
  end

  def self.send_field_to_similarity_index(pm, field)
    if pm.send(field).blank?
      self.delete_field_from_text_similarity_index(pm, field, true)
    else
      self.send_to_text_similarity_index(pm, field, pm.send(field), self.item_doc_id(pm, field))
    end
  end

  def self.team_has_alegre_bot_installed?(team_id)
    tbi = self.get_alegre_tbi(team_id)
    !tbi.nil?
  end

  def self.indexing_model_to_use(pm)
    tbi = self.get_alegre_tbi(pm&.team_id)
    tbi.nil? ? self.default_model : tbi.get_alegre_model_in_use || self.default_model
  end

  def self.matching_model_to_use(pm)
    tbi = self.get_alegre_tbi(pm&.team_id)
    tbi.nil? ? self.default_matching_model : tbi.get_text_similarity_model || self.default_matching_model
  end

  def self.get_alegre_tbi(team_id)
    bot = BotUser.alegre_user
    tbi = TeamBotInstallation.find_by_team_id_and_user_id(team_id, bot&&bot.id)
    tbi
  end

  def self.delete_field_from_text_similarity_index(pm, field, quiet=false)
    self.delete_from_text_similarity_index(self.item_doc_id(pm, field), quiet)
  end

  def self.delete_from_text_similarity_index(doc_id, quiet=false)
    self.request_api('delete', '/text/similarity/', {
      doc_id: doc_id,
      quiet: quiet
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

  def self.send_to_media_similarity_index(pm)
    type = nil
    if pm.report_type == 'uploadedimage'
      type = 'image'
    elsif pm.report_type == 'uploadedvideo'
      type = 'video'
    elsif pm.report_type == 'uploadedaudio'
      type = 'audio'
    end
    unless type.blank?
      params = {
        doc_id: self.item_doc_id(pm, type),
        url: self.media_file_url(pm),
        context: {
          team_id: pm.team_id,
          project_media_id: pm.id,
          has_custom_id: true
        }
      }
      self.request_api(
        'post',
        "/#{type}/similarity/",
        params
      )
    end
  end

  def self.request_api(method, path, params = {}, query_or_body = 'body', retries = 3)
    uri = URI(CheckConfig.get('alegre_host') + path)
    klass = 'Net::HTTP::' + method.capitalize
    request = klass.constantize.new(uri.path, 'Content-Type' => 'application/json')
    if query_or_body == 'query'
      request.set_form_data(params)
      request = Net::HTTP::Get.new(uri.path+ '?' + request.body)
    else
      request.body = params.to_json
    end
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = uri.scheme == 'https'
    begin
      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      if retries > 0
        sleep 1
        self.request_api(method, path, params, query_or_body , retries - 1)
      end
      Rails.logger.error("[Alegre Bot] Alegre error: #{e.message}")
      self.notify_error(e, { method: method, bot: self.name, url: uri, params: params }, RequestStore[:request] )
      { 'type' => 'error', 'data' => { 'message' => e.message } }
    end
  end

  def self.split_text(text)
    text.split(/\s/)
  end

  def self.get_items_with_similar_title(pm, threshold)
    pm.original_title.blank? ? {} : self.get_merged_similar_items(pm, threshold, ['original_title', 'report_text_title', 'report_visual_card_title'], pm.original_title)
  end

  def self.get_items_with_similar_description(pm, threshold, input_description = nil)
    description = input_description || pm.original_description
    description.blank? ? {} : self.get_merged_similar_items(pm, threshold, ['original_description', 'report_text_content', 'report_visual_card_content', 'extracted_text'], description)
  end

  def self.get_merged_similar_items(pm, threshold, fields, value)
    output = {}
    fields.each do |field|
      response = self.get_items_with_similar_text(pm, field, threshold, value, self.default_matching_model)
      output[field] = response unless response.blank?
    end

    if self.matching_model_to_use(pm) != self.default_matching_model
      fields.each do |field|
        response = self.get_items_with_similar_text(pm, field, threshold, value)
        output[field] = response unless response.blank?
      end
    end
    es_matches = output.values.reduce({}, :merge)
    # set matched fields to use in short-text suggestion
    pm.alegre_matched_fields ||= []
    pm.alegre_matched_fields.concat(output.keys)
    es_matches
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
    self.get_source_key_from_image_or_text_response(search_result, 'context')
  end

  def self.get_source_key_from_image_or_text_response(search_result, source_key)
    search_result.dig('_source', source_key) || search_result.dig(source_key)
  end

  def self.get_score_from_image_or_text_response(search_result)
    (search_result.with_indifferent_access.dig('_score')||search_result.with_indifferent_access.dig('score'))
  end

  def self.get_similar_items_from_api(path, conditions, _threshold={})
    Rails.logger.error("[Alegre Bot] Sending request to alegre : #{path} , #{conditions.to_json}")
    response = {}
    result = self.request_api('get', path, conditions).dig('result')
    project_medias = result.collect{ |r| self.extract_project_medias_from_context(r) } if !result.nil? && result.is_a?(Array)
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

  def self.build_context(team_id, field = nil)
    context = { has_custom_id: true }
    context[:field] = field unless field.blank?
    context[:team_id] = team_id unless team_id.blank?
    context
  end

  def self.get_items_from_similar_text(team_id, text, field = nil, threshold = nil, model = nil, fuzzy = false)
    field ||= (['original_title', 'original_description'] + REPORT_TEXT_SIMILARITY_FIELDS).flatten
    threshold ||= self.get_threshold_for_query('text', nil, true)
    model ||= self.matching_model_to_use(ProjectMedia.new(team_id: team_id))
    self.get_similar_items_from_api(
      '/text/similarity/',
      self.similar_texts_from_api_conditions(text, model, fuzzy, team_id, field, threshold),
      threshold
    )
  end

  def self.similar_texts_from_api_conditions(text, model, fuzzy, team_id, field, threshold)
    {
      text: text,
      model: model,
      fuzzy: fuzzy == 'true' || fuzzy.to_i == 1,
      context: self.build_context(team_id, field),
      threshold: threshold[:value]
    }
  end

  def self.get_items_with_similar_media(media_url, threshold, team_id, path)
    self.get_similar_items_from_api(
      path,
      self.similar_media_content_from_api_conditions(team_id, media_url, threshold)
    )
  end

  def self.reject_same_case(results, pm)
    results.reject{ |id, _score| pm.id == id }
  end

  def self.similar_media_content_from_api_conditions(team_id, media_url, threshold)
    {
      url: media_url,
      context: self.build_context(team_id),
      threshold: threshold[:value]
    }
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

    self.add_relationship(pm, pm_id_scores, parent_id)
  end

  def self.add_relationship(pm, pm_id_scores, parent_id)
    # Better be safe than sorry.
    return if parent_id == pm.id
    parent = ProjectMedia.find_by_id(parent_id)
    return false if parent.nil?
    if parent.is_blank?
      parent.replace_by(pm)
    elsif pm_id_scores[parent_id]
      relationship_type = self.set_relationship_type(pm, pm_id_scores, parent)
      self.create_relationship(parent, pm, pm_id_scores[parent_id][:score], relationship_type)
    end
  end

  def self.create_relationship(source, target, weight, relationship_type)
    r = Relationship.new
    r.skip_check_ability = true
    r.relationship_type = relationship_type
    r.weight = weight
    r.source_id = source.id
    r.target_id = target.id
    r.user_id ||= BotUser.alegre_user&.id
    r.save!
    CheckNotification::InfoMessages.send(
      r.is_confirmed? ? 'related_to_confirmed_similar' : 'related_to_suggested_similar',
      item_title: target.title,
      similar_item_title: source.title
    )
    r
  end

  def self.set_relationship_type(pm, pm_id_scores, parent)
    tbi = self.get_alegre_tbi(pm&.team_id)
    settings = tbi.nil? ? {} : tbi.alegre_settings
    date_threshold = Time.now - settings['similarity_date_threshold'].to_i.months unless settings['similarity_date_threshold'].blank?
    relationship_type = pm_id_scores[parent.id][:relationship_type]
    if settings['date_similarity_threshold_enabled'] && !date_threshold.blank? && parent.created_at.to_i < date_threshold.to_i
      relationship_type = Relationship.suggested_type
    else
      length_threshold = settings.blank? ? CheckConfig.get('text_length_matching_threshold').to_f : settings['text_length_matching_threshold'].to_f
      relationship_type = Relationship.suggested_type if self.is_text_too_short?(pm, length_threshold)
    end
    relationship_type
  end

  def self.is_text_too_short?(pm, length_threshold)
    is_short = false
    unless pm.alegre_matched_fields.blank?
      fields_size = []
      pm.alegre_matched_fields.uniq.each do |field|
        fields_size << self.split_text(pm.send(field).to_s).length if pm.respond_to?(field)
      end
      is_short = fields_size.max < length_threshold unless fields_size.blank?
    end
    is_short
  end

  class <<self
    alias_method :get_similar_texts, :get_items_from_similar_text
  end

end
