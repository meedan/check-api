class Bot::Alegre < BotUser
  check_settings
  class Error < ::StandardError
  end

  include AlegreSimilarity

  # Text similarity models
  MEAN_TOKENS_MODEL = 'xlm-r-bert-base-nli-stsb-mean-tokens'
  INDIAN_MODEL = 'indian-sbert'
  FILIPINO_MODEL = 'mdeberta-v3-filipino'
  ELASTICSEARCH_MODEL = 'elasticsearch'

  REPORT_TEXT_SIMILARITY_FIELDS = ['report_text_title', 'report_text_content', 'report_visual_card_title', 'report_visual_card_content']
  ALL_TEXT_SIMILARITY_FIELDS = REPORT_TEXT_SIMILARITY_FIELDS + ['original_title', 'original_description', 'extracted_text', 'transcription', 'claim_description_content', 'fact_check_title', 'fact_check_summary']

  ::ProjectMedia.class_eval do
    attr_accessor :alegre_similarity_thresholds, :alegre_matched_fields

    def similar_items_ids_and_scores(team_ids)
      ids_and_scores = {}
      if self.is_media?
        media_type = {
          'UploadedVideo' => 'video',
          'UploadedAudio' => 'audio',
          'UploadedImage' => 'image',
        }[self.media.type]
        threshold = Bot::Alegre.get_threshold_for_query(media_type, self, true)[:value]
        ids_and_scores = Bot::Alegre.get_items_with_similar_media(Bot::Alegre.media_file_url(self), { value: threshold }, team_ids, "/#{media_type}/similarity/").to_h
      elsif self.is_text?
        ids_and_scores = {}
        threads = []
        ALL_TEXT_SIMILARITY_FIELDS.each do |field|
          text = self.send(field)
          next if text.blank?
          threads << Thread.new { ids_and_scores.merge!(Bot::Alegre.get_similar_texts(team_ids, text).to_h) }
        end
        threads.map(&:join)
      end
      ids_and_scores.delete(self.id)
      ids_and_scores
    end

    def similar_items
      team_ids = User.current&.is_admin? ? ProjectMedia.where.not(cluster_id: nil).group(:team_id).count.keys : [self.team_id]
      ids = self.similar_items_ids_and_scores(team_ids).keys.flatten.uniq
      ProjectMedia.where(id: ids.empty? ? [0] : ids.reject{ |id| id == self.id })
    end
  end

  Dynamic.class_eval do
    after_commit :send_annotation_data_to_similarity_index, if: :can_be_sent_to_index?, on: [:create, :update]
    after_create :match_similar_items_using_ocr, :get_language_from_ocr
    after_update :match_similar_items_using_transcription, :get_language_from_transcription

    def self.send_annotation_data_to_similarity_index(pm_id, annotation_type)
      pm = ProjectMedia.find_by_id(pm_id)
      if annotation_type == 'report_design'
        REPORT_TEXT_SIMILARITY_FIELDS.each do |field|
          Bot::Alegre.send_field_to_similarity_index(pm, field)
        end
      elsif annotation_type == 'extracted_text'
        Bot::Alegre.send_field_to_similarity_index(pm, 'extracted_text')
      elsif annotation_type == 'transcription'
        Bot::Alegre.send_field_to_similarity_index(pm, 'transcription')
      end
    end

    def self.match_similar_items_by_type(id, type)
      annotation = Dynamic.find_by_id(id)
      if annotation && annotation.annotation_type == type
        pm = annotation.annotated
        text = annotation.get_field_value('text')
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] An annotation of type #{type} was saved, so we are looking for items with similar description to #{pm.id} (text is '#{text}')")
        return if text.blank? || !Bot::Alegre.should_get_similar_items_of_type?('master', pm.team_id) || !Bot::Alegre.should_get_similar_items_of_type?(type, pm.team_id)
        matches = Bot::Alegre.return_prioritized_matches(Bot::Alegre.merge_response_with_source_and_target_fields(Bot::Alegre.get_items_with_similar_description(pm, Bot::Alegre.get_threshold_for_query('text', pm), text), type)).first
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] An annotation of type #{type} was saved, so the items with similar description to #{pm.id} (text is '#{text}') are: #{matches.inspect}")
        unless matches.nil?
          match_id, score_with_context = matches
          match = ProjectMedia.find_by_id(match_id)
          existing_parent = Relationship.where(target_id: match_id).where('relationship_type IN (?)', [Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml]).first
          parent = existing_parent.nil? ? match : existing_parent.source
          Bot::Alegre.create_relationship(parent, pm, score_with_context, Relationship.suggested_type)
        end
      end
    end

    def self.get_language_from_extracted_text(id, type)
      annotation = Dynamic.find_by_id(id)
      ::Bot::Alegre.get_language_from_text(annotation.annotated, annotation.get_field_value('text')) if annotation&.annotation_type == type
    end

    private

    def can_be_sent_to_index?
      ['report_design', 'extracted_text', 'transcription'].include?(self.annotation_type) &&
      Bot::Alegre.team_has_alegre_bot_installed?(self.annotated&.team&.id&.to_i)
    end

    def send_annotation_data_to_similarity_index
      self.class.delay_for(5.seconds, retry: 5).send_annotation_data_to_similarity_index(self.annotated_id, self.annotation_type)
    end

    def match_similar_items_using_ocr
      self.class.delay_for(15.seconds, retry: 5).match_similar_items_by_type(self.id, 'extracted_text')
    end

    def match_similar_items_using_transcription
      self.class.delay_for(15.seconds, retry: 5).match_similar_items_by_type(self.id, 'transcription')
    end

    def get_language_from_ocr
      self.class.delay_for(15.seconds, retry: 5).get_language_from_extracted_text(self.id, 'extracted_text')
    end

    def get_language_from_transcription
      self.class.delay_for(15.seconds, retry: 5).get_language_from_extracted_text(self.id, 'transcription')
    end
  end

  def self.default_model
    CheckConfig.get('alegre_default_model') || Bot::Alegre::ELASTICSEARCH_MODEL
  end

  def self.default_matching_model
    Bot::Alegre::ELASTICSEARCH_MODEL
  end

  def self.run(body)
    Rails.logger.info("[Alegre Bot] Received event with body of #{body}")
    if CheckConfig.get('alegre_host').blank?
      Rails.logger.warn("[Alegre Bot] Skipping events because `alegre_host` config is blank")
      return false
    end

    handled = false
    pm = nil
    begin
      pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
      if body.dig(:event) == 'create_project_media' && !pm.nil?
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] This item was just created, processing...")
        self.get_language(pm)
        self.send_to_media_similarity_index(pm)
        self.send_field_to_similarity_index(pm, 'original_title')
        self.send_field_to_similarity_index(pm, 'original_description')
        self.get_extracted_text(pm)
        self.relate_project_media_to_similar_items(pm)
        self.get_flags(pm)
        self.auto_transcription(pm)
        self.set_cluster(pm)
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Exception for event `#{body['event']}`: #{e.message}")
      self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
    end

    self.unarchive_if_archived(pm)

    handled
  end

  def self.set_cluster(pm, force = false)
    team_ids = ProjectMedia.where.not(cluster_id: nil).group(:team_id).count.keys
    pm = ProjectMedia.find(pm.id)
    return if (!pm.cluster_id.blank? || !team_ids.include?(pm.team_id)) && !force
    ids_and_scores = pm.similar_items_ids_and_scores(team_ids)
    main_id = ids_and_scores.max_by{ |_pm_id, score_and_context| score_and_context[:score] }&.first
    main = ProjectMedia.find_by_id(main_id.to_i)
    cluster = main&.cluster
    unless cluster
      cluster = Cluster.new
      cluster.project_media = pm
      cluster.skip_check_ability = true
      cluster.save!
    end
    cluster.project_medias << pm
    cluster
  end

  def self.get_number_of_words(text)
    text.gsub(/[^\p{L}\s]/u, '').strip.chomp.split(/\s+/).size
  end

  def self.get_items_from_similar_text(team_id, text, field = nil, threshold = nil, model = nil, fuzzy = false)
    return {} if text.blank? || self.get_number_of_words(text) < 3
    field ||= ALL_TEXT_SIMILARITY_FIELDS
    threshold ||= self.get_threshold_for_query('text', nil, true)
    model ||= self.matching_model_to_use(ProjectMedia.new(team_id: team_id))
    Hash[self.get_similar_items_from_api(
      '/text/similarity/',
      self.similar_texts_from_api_conditions(text, model, fuzzy, team_id, field, threshold),
      threshold
    ).collect{|k,v| [k, v.merge(model: model)]}]
  end

  def self.unarchive_if_archived(pm)
    if pm&.archived == CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS
      pm.update_column(:archived, CheckArchivedFlags::FlagCodes::NONE)
      sources_count = Relationship.where(target_id: pm.id).where('relationship_type = ?', Relationship.confirmed_type.to_yaml).count
      pm.update_elasticsearch_doc(['archived', 'sources_count'], { 'archived' => CheckArchivedFlags::FlagCodes::NONE, 'sources_count' => sources_count }, pm)
    end
  end

  def self.valid_match_types(type)
    {
      "Claim" => ["text"],
      "Link" => ["text"],
      "UploadedImage" => ["image"],
      "UploadedVideo" => ["video", "audio"],
      "UploadedAudio" => ["audio", "video"]
      }[type] || []
  end

  def self.restrict_to_same_modality(pm, matches)
    other_pms = Hash[ProjectMedia.where(id: matches.keys).includes(:media).all.collect{ |item| [item.id, item] }]
    if pm.is_text?
      matches.select{ |k, _v| other_pms[k.to_i]&.is_text? || !other_pms[k.to_i]&.extracted_text.blank? || !other_pms[k.to_i]&.transcription.blank? || other_pms[k.to_i]&.is_blank? }
    else
      matches.select{ |k, _v| (self.valid_match_types(other_pms[k.to_i]&.media&.type) & self.valid_match_types(pm.media.type)).length > 0 }
    end
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

  def self.get_language(pm)
    self.get_language_from_text(pm, pm.text)
  end

  def self.get_language_from_text(pm, text)
    lang = text.blank? ? 'und' : self.get_language_from_alegre(text)
    self.save_annotation(pm, 'language', { language: lang })
    lang
  end

  def self.auto_transcription(pm)
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Auto Transcription 1/5] Attempting auto transcription"
    Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Auto Transcription 2/5] Not proceeding with auto transcription because workspace similarity settings don't enable it") and return if !Bot::Alegre.should_get_similar_items_of_type?('master', pm.team_id) || !Bot::Alegre.should_get_similar_items_of_type?('transcription', pm.team_id)
    if ['uploadedaudio', 'uploadedvideo'].include?(pm.report_type)
      Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Auto Transcription 3/5] Proceeding with auto transcription because item is an audio or video")
      tbi = self.get_alegre_tbi(pm&.team_id)
      settings = tbi.nil? ? {} : tbi.alegre_settings
      min_requests = settings['transcription_minimum_requests'].to_i
      if pm.requests_count >= min_requests
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Auto Transcription 4/5] Proceeding with auto transcription because item has #{pm.requests_count} requests, which is equal or above the minimum of #{min_requests}")
        url = self.media_file_url(pm)
        tempfile = Tempfile.new('transcription', binmode: true)
        tempfile.write(open(url).read)
        tempfile.close
        media = FFMPEG::Movie.new(tempfile.path)
        min, max = settings['transcription_minimum_duration'].to_f, settings['transcription_maximum_duration'].to_f
        dur = media.duration
        if dur.between?(min, max)
          Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Auto Transcription 5/5] Proceeding with auto transcription because media has #{dur} seconds, which is between the minimum (#{min} seconds) and maximum (#{max} seconds) configured settings for this workspace")
          self.transcribe_audio(pm)
        end
        tempfile.unlink
      end
    end
  end

  def self.get_language_from_alegre(text)
    lang = 'und'
    begin
      response = self.request_api('post', '/text/langid/', { text: text })
      lang = response['result']['language'] || lang
    rescue
      nil
    end
    lang
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

  def self.update_audio_transcription(transcription_annotation_id, attempts)
    annotation = Dynamic.find(transcription_annotation_id)
    result = self.request_api('get', '/audio/transcription/', { job_name: annotation.get_field_value('job_name') })
    completed = false
    if result['job_status'] == 'COMPLETED'
      annotation.disable_es_callbacks = Rails.env.to_s == 'test'
      annotation.set_fields = { text: result['transcription'], last_response: result }.to_json
      annotation.skip_check_ability = true
      annotation.save!
      completed = true
    end
    self.delay_for(10.seconds, retry: 5).update_audio_transcription(annotation.id, attempts + 1) if !completed && attempts < 2000 # Maximum: ~5h of transcription
  end

  def self.transcribe_audio(pm)
    annotation = nil
    if pm.report_type == 'uploadedaudio' || pm.report_type == 'uploadedvideo'
      url = self.media_file_url(pm)
      job_name = Digest::MD5.hexdigest(open(url).read)
      s3_url = url.gsub(/^https?:\/\/[^\/]+/, "s3://#{CheckConfig.get('storage_bucket')}")
      result = self.request_api('post', '/audio/transcription/', { url: s3_url, job_name: job_name })
      annotation = self.save_annotation(pm, 'transcription', { text: '', job_name: job_name, last_response: result }) if result
      # FIXME: Calculate schedule interval based on audio duration
      self.delay_for(10.seconds, retry: 5).update_audio_transcription(annotation.id, 1)
    end
    annotation
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
      Rails.logger.info("[Alegre Bot] Alegre Bot request: (#{method}, #{path}, #{params.inspect}, #{query_or_body}, #{retries})")
      response_body = response.body
      Rails.logger.info("[Alegre Bot] Alegre response: #{response_body.inspect}")
      JSON.parse(response_body)
    rescue StandardError => e
      if retries > 0
        sleep 1
        self.request_api(method, path, params, query_or_body , retries - 1)
      end
      Rails.logger.error("[Alegre Bot] Alegre error: #{e.message}")
      { 'type' => 'error', 'data' => { 'message' => e.message } }
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
    Hash[pms.flatten.collect{ |pm| [pm.to_i, {score: self.get_score_from_image_or_text_response(search_result), context: context}] }]
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

  def self.build_context(team_id, field = nil)
    context = { has_custom_id: true }
    context[:field] = field unless field.blank?
    context[:team_id] = team_id unless team_id.blank?
    context
  end

  def self.return_prioritized_matches(pm_id_scores)
    pm_id_scores.sort_by{|k,v| [Bot::Alegre::ELASTICSEARCH_MODEL != v[:model] ? 1 : 0, v[:score], -k]}.reverse
  end

  def self.add_relationships(pm, pm_id_scores)
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 1/6] Adding relationships for #{pm_id_scores.inspect}"
    return if pm_id_scores.blank? || pm_id_scores.keys.include?(pm.id)

    # Take first match as being the best potential parent.
    # Conditions to check for a valid parent in 2-level hierarchy:
    # - If it's a child, get its parent.
    # - If it's a parent, use it.
    # - If it has no existing relationship, use it.
    #make K negative so that we bias towards older IDs
    parent_id = self.return_prioritized_matches(pm_id_scores).first.first
    parent_relationships = Relationship.where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).where(target_id: parent_id).all
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 2/6] Number of parent relationships #{parent_relationships.count}"
    if parent_relationships.length > 0
      # Sanity check: if there are multiple parents, something is wrong in the dataset.
      self.notify_error(StandardError.new("[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships ERROR] Found multiple similarity relationship parents for ProjectMedia #{parent_id}"), {}, RequestStore[:request]) if parent_relationships.length > 1
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
      original_parent_id = parent_id
      parent_id = parent_relationship.source_id
      pm_id_scores[parent_id] = pm_id_scores[original_parent_id]
      pm_id_scores[parent_id][:relationship_type] = new_type if pm_id_scores[parent_id]
    end
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 3/6] Adding relationship for following pm_id, pm_id_scores, parent_id #{[pm.id, pm_id_scores, parent_id].inspect}"
    self.add_relationship(pm, pm_id_scores, parent_id)
  end

  def self.add_relationship(pm, pm_id_scores, parent_id)
    # Better be safe than sorry.
    return if parent_id == pm.id
    parent = ProjectMedia.find_by_id(parent_id)
    return false if parent.nil?
    if parent.is_blank?
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 4/6] Parent is blank, creating suggested relationship"
      self.create_relationship(parent, pm, pm_id_scores[parent_id], Relationship.suggested_type)
    elsif pm_id_scores[parent_id]
      relationship_type = self.set_relationship_type(pm, pm_id_scores, parent)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 4/6] Parent is blank, creating relationship of #{relationship_type.inspect}"
      self.create_relationship(parent, pm, pm_id_scores[parent_id], relationship_type)
    end
  end

  def self.get_indexing_model(pm, score_with_context)
    score_with_context[:model] || self.get_pm_type(pm)
  end

  def self.is_suggested_to_trash(source, target, relationship_type)
    relationship_type == Relationship.suggested_type && (source.archived == CheckArchivedFlags::FlagCodes::TRASHED || target.archived == CheckArchivedFlags::FlagCodes::TRASHED)
  end

  def self.create_relationship(source, target, score_with_context, relationship_type)
    return if source.nil? || target.nil?
    score = score_with_context[:score]
    context = score_with_context[:context]
    source_field = score_with_context[:source_field]
    target_field = score_with_context[:target_field]
    r = Relationship.where(source_id: source.id, target_id: target.id)
    .where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).last
    return if self.is_suggested_to_trash(source, target, relationship_type)
    if r.nil?
      # Ensure that target relationship is confirmed before creating the relation `CHECK-907`
      if target.archived != CheckArchivedFlags::FlagCodes::NONE
        target.archived = CheckArchivedFlags::FlagCodes::NONE
        target.save!
      end
      r = Relationship.new
      r.skip_check_ability = true
      r.relationship_type = relationship_type
      r.model = self.get_indexing_model(source, score_with_context)
      r.weight = score
      r.details = context
      r.source_id = source.id
      r.target_id = target.id
      r.source_field = source_field
      r.target_field = target_field
      r.user_id ||= BotUser.alegre_user&.id
      r.save!
      self.throw_airbrake_notify_if_bad_relationship(r, score_with_context, relationship_type)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{target.id}] [Relationships 5/6] Created new relationship for relationship ID Of #{r.id}"
    elsif r.relationship_type != relationship_type && r.relationship_type == Relationship.suggested_type
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{target.id}] [Relationships 5/6] Upgrading relationship from suggested to confirmed for relationship ID of #{r.id}"
      # confirm existing relation if a new one is confirmed
      r.relationship_type = relationship_type
      r.save!
    end
    message_type = r.is_confirmed? ? 'related_to_confirmed_similar' : 'related_to_suggested_similar'
    message_opts = {item_title: target.title, similar_item_title: source.title}
    CheckNotification::InfoMessages.send(
      message_type,
      message_opts
    )
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{target.id}] [Relationships 6/6] Sent Check notification with message type and opts of #{[message_type, message_opts].inspect}"
    r
  end

  def self.throw_airbrake_notify_if_bad_relationship(relationship, score_with_context, relationship_type)
    if relationship.model.nil? || relationship.weight.nil? || relationship.source_field.nil? || relationship.target_field.nil? || ![MEAN_TOKENS_MODEL, INDIAN_MODEL, ELASTICSEARCH_MODEL, 'audio', 'image', 'video'].include?(relationship.model)
      Airbrake.notify(Bot::Alegre::Error.new("[Alegre] Bad relationship was stored without required metadata"), {trace: Thread.current.backtrace.join("\n"), relationship: relationship.attributes, relationship_type: relationship_type, score_with_context: score_with_context}) if Airbrake.configured?
    end
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
        fields_size << pm.send(field).to_s.split(/\s/).length if pm.respond_to?(field)
      end
      is_short = fields_size.max < length_threshold unless fields_size.blank?
    end
    is_short
  end

  class <<self
    alias_method :get_similar_texts, :get_items_from_similar_text
  end

end
