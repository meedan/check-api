require 'open-uri'
require 'uri'

class Bot::Alegre < BotUser
  check_settings
  class Error < ::StandardError
  end

  include AlegreSimilarity
  include AlegreWebhooks
  include AlegreV2

  # Text similarity models
  MEAN_TOKENS_MODEL = 'xlm-r-bert-base-nli-stsb-mean-tokens'
  INDIAN_MODEL = 'indian-sbert'
  FILIPINO_MODEL = 'paraphrase-filipino-mpnet-base-v2'
  OPENAI_ADA_MODEL = 'openai-text-embedding-ada-002'
  PARAPHRASE_MULTILINGUAL_MODEL = 'paraphrase-multilingual-mpnet-base-v2'
  ELASTICSEARCH_MODEL = 'elasticsearch'

  TEXT_MODEL_RANKS = { # Higher is better
    Bot::Alegre::OPENAI_ADA_MODEL => 3,
    Bot::Alegre::PARAPHRASE_MULTILINGUAL_MODEL => 2,
    Bot::Alegre::FILIPINO_MODEL => 2,
    Bot::Alegre::MEAN_TOKENS_MODEL => 1,
    Bot::Alegre::INDIAN_MODEL => 1,
    Bot::Alegre::ELASTICSEARCH_MODEL => 0
  }

  DEFAULT_ES_SCORE = 10

  REPORT_TEXT_SIMILARITY_FIELDS = ['report_text_title', 'report_text_content', 'report_visual_card_title', 'report_visual_card_content']
  ALL_TEXT_SIMILARITY_FIELDS = REPORT_TEXT_SIMILARITY_FIELDS + ['original_title', 'original_description', 'extracted_text', 'transcription', 'claim_description_content', 'fact_check_title', 'fact_check_summary']
  BAD_TITLE_REGEX = /^[a-z\-]+-[0-9\-]+$|^#{URI.regexp}$/
  ::ProjectMedia.class_eval do
    attr_accessor :alegre_similarity_thresholds, :alegre_matched_fields

    def similar_items_ids_and_scores(team_ids, thresholds = {})
      ids_and_scores = {}
      if self.is_media?
        media_type = {
          'UploadedVideo' => 'video',
          'UploadedAudio' => 'audio',
          'UploadedImage' => 'image',
        }[self.media.type].to_s
        threshold = [{value: thresholds.dig(media_type.to_sym, :value)}] || Bot::Alegre.get_threshold_for_query(media_type, self, true)
        ids_and_scores = Bot::Alegre.get_items_with_similar_media_v2(project_media: self, threshold: threshold, team_ids: team_ids, media_type: media_type).to_h
      elsif self.is_text?
        ids_and_scores = {}
        threads = []
        ALL_TEXT_SIMILARITY_FIELDS.each do |field|
          text = self.send(field)
          next if text.blank?
          threads << Thread.new { ids_and_scores.merge!(Bot::Alegre.get_items_from_similar_text(team_ids, text, Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, thresholds[:text]).to_h) }
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
      return if pm.nil?
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
        matches = Bot::Alegre.return_prioritized_matches(Bot::Alegre.merge_response_with_source_and_target_fields(Bot::Alegre.get_items_with_similar_description(pm, Bot::Alegre.get_threshold_for_query('text', pm), text), type))
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] An annotation of type #{type} was saved, so the items with similar description to #{pm.id} (text is '#{text}') are: #{matches.inspect}")
        unless matches.nil?
          match_id, _score_with_context = matches.first
          match = ProjectMedia.find_by_id(match_id)
          existing_parent = Relationship.where(target_id: match_id).where('relationship_type IN (?)', [Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml]).first
          hashed_matches = Hash[matches]
          if existing_parent&.source
            hashed_matches[existing_parent.source.id] ||= hashed_matches[match.id]
          end
          Bot::Alegre.create_relationship(existing_parent&.source || match, pm, hashed_matches, Relationship.suggested_type, match, Relationship.suggested_type)
        end
      end
    end

    def self.get_language_from_extracted_text(id)
      annotation = Dynamic.find_by_id(id)
      ::Bot::Alegre.get_language_from_text(annotation.annotated, annotation.get_field_value('text'))
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
      self.class.delay_for(15.seconds, retry: 5).match_similar_items_by_type(self.id, 'extracted_text') if self.annotation_type == 'extracted_text'
    end

    def match_similar_items_using_transcription
      self.class.delay_for(15.seconds, retry: 5).match_similar_items_by_type(self.id, 'transcription') if self.annotation_type == 'transcription'
    end

    def get_language_from_ocr
      self.class.delay_for(15.seconds, retry: 5).get_language_from_extracted_text(self.id) if self.annotation_type == 'extracted_text'
    end

    def get_language_from_transcription
      self.class.delay_for(15.seconds, retry: 5).get_language_from_extracted_text(self.id) if self.annotation_type == 'transcription'
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
        if ['audio', 'image', 'video'].include?(self.get_pm_type(pm))
          self.relate_project_media_async(pm) if self.media_file_url(pm)
        else
          self.relate_project_media_async(pm, 'original_title') if pm.original_title
          self.relate_project_media_async(pm, 'original_description') if pm.original_description
        end
        self.get_extracted_text(pm)
        self.get_flags(pm)
        self.auto_transcription(pm)
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[Alegre Bot] Exception for event `#{body['event']}`: #{e.message}")
      CheckSentry.notify(e, bot: self.name, body: body)
    end

    self.unarchive_if_archived(pm)

    handled
  end

  def self.get_number_of_words(text)
    # Get the number of space-separated words (Does not work with Chinese/Japanese)
    space_separted_words = text.to_s.gsub(/[^\p{L}\s]/u, '').strip.chomp.split(/\s+/).size

    # This removes URLs
    # Then it splits the text on any non unicode word boundary (works with Chinese, Japanese)
    # We then clean each word and remove any empty ones
    unicode_words = text.to_s.gsub(/https?:\/\/\S+/u, '').scan(/(?u)\w+/).map{|w| w.gsub(/[^\p{L}\s]/u, '').strip.chomp}.reject{|w| w.length==0}
    # For each word, we:
    # Get the number of Chinese characters. We'll assume two characters are like one word
    # Get the number of Japanese hiragana/katakana (kana) characters.
    # Kana are definitely not one word each, but who really knows.
    # For the purpose of this function, we'll assume 4 kana equate to one word
    unicode_words = unicode_words.map{|w| [1,
      (w.scan(/\p{Han}/).size/2.0).ceil + (w.scan(/\p{Katakana}|\p{Hiragana}/).size/4.0).ceil].max}.sum()

    # Return whichever is larger of our two methods for counting words
    [space_separted_words, unicode_words].max
  end

  def self.get_items_from_similar_text(team_id, text, fields = nil, threshold = nil, models = nil, fuzzy = false)
    team_ids = [team_id].flatten
    if text.blank? || BAD_TITLE_REGEX =~ text
      Rails.logger.info("[Alegre Bot] get_items_from_similar_text returning early due to blank/bad text #{text}")
      return {}
    end
    fields ||= ALL_TEXT_SIMILARITY_FIELDS
    threshold ||= self.get_threshold_for_query('text', nil, true)
    models ||= [self.matching_model_to_use(team_ids)].flatten
    Hash[self.get_similar_items_from_api(
      'text',
      self.similar_texts_from_api_conditions(text, models, fuzzy, team_ids, fields, threshold),
      threshold
    ).collect{|k,v| [k, v.merge(model: v[:model]||Bot::Alegre.default_matching_model)]}]
  end

  def self.unarchive_if_archived(pm)
    if pm&.archived == CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS
      pm.update_column(:archived, CheckArchivedFlags::FlagCodes::NONE)
      pm.update_elasticsearch_doc(['archived'], { 'archived' => CheckArchivedFlags::FlagCodes::NONE }, pm.id)
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
      selected_matches = matches.select{ |k, _v| other_pms[k.to_i]&.is_text? || !other_pms[k.to_i]&.extracted_text.blank? || !other_pms[k.to_i]&.transcription.blank? || other_pms[k.to_i]&.is_blank? }
    else
      selected_matches = matches.select{ |k, _v| (self.valid_match_types(other_pms[k.to_i]&.media&.type) & self.valid_match_types(pm.media.type)).length > 0 }
    end
    selected_matches
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

  def self.get_threshold_given_model_settings(team_id, media_type, similarity_method, automatic, model_name)
    tbi = nil
    tbi = self.get_alegre_tbi(team_id) unless team_id.nil?
    similarity_level = automatic ? 'matching' : 'suggestion'
    generic_key = "#{media_type}_#{similarity_method}_#{similarity_level}_threshold"
    specific_key = "#{media_type}_#{similarity_method}_#{model_name}_#{similarity_level}_threshold"
    settings = tbi.alegre_settings unless tbi.nil?
    outkey = ""
    value = nil
    [specific_key, generic_key].each do |key|
      next if !outkey.blank?
      value = settings.blank? ? CheckConfig.get(key) : settings[key]
      if value
        outkey = key
      end
    end
    return [outkey, value]
  end

  def self.get_matching_key_value(pm, media_type, similarity_method, automatic, model_name)
    self.get_threshold_given_model_settings(pm&.team_id, media_type, similarity_method, automatic, model_name)
  end

  def self.get_similarity_methods_and_models_given_media_type_and_team_id(media_type, team_id, get_vector_settings)
    similarity_methods = media_type == 'text' ? ['elasticsearch'] : ['hash']
    models = similarity_methods.dup
    if media_type == 'text' && get_vector_settings
      models_to_use = [self.matching_model_to_use(team_id)].flatten-[Bot::Alegre::ELASTICSEARCH_MODEL]
      models_to_use.each do |model|
        similarity_methods << 'vector'
        models << model
      end
    end
    return similarity_methods.zip(models)
  end

  def self.get_threshold_for_query(media_type, pm, automatic = false)
    self.get_similarity_methods_and_models_given_media_type_and_team_id(media_type, pm&.team_id, !pm.nil?).collect do |similarity_method, model_name|
      key, value = self.get_matching_key_value(pm, media_type, similarity_method, automatic, model_name)
      { value: value.to_f, key: key, automatic: automatic, model: model_name}
    end
  end

  def self.get_language(pm)
    self.get_language_from_text(pm, pm.text)
  end

  def self.get_language_from_text(pm, text)
    lang = 'und'
    if !text.blank? && BAD_TITLE_REGEX !~ text
      lang = self.get_language_from_alegre(text)
    end
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
        tempfile.write(URI(url).open.read)
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
      response = self.request('post', '/text/langid/', { text: text })
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
      result = self.request('post', '/image/classification/', { uri: self.media_file_url(pm) })
      self.save_annotation(pm, 'flag', result['result'])
    end
  end

  def self.get_extracted_text(pm)
    if pm.report_type == 'uploadedimage'
      result = self.request('post', '/image/ocr/', { url: self.media_file_url(pm) })
      self.save_annotation(pm, 'extracted_text', result) if result
    end
  end

  def self.update_audio_transcription(transcription_annotation_id, attempts)
    annotation = Dynamic.find(transcription_annotation_id)
    result = self.request('post', '/audio/transcription/result/', { job_name: annotation.get_field_value('job_name') })
    completed = false
    if result['job_status'] == 'COMPLETED'
      annotation.disable_es_callbacks = Rails.env.to_s == 'test'
      annotation.set_fields = { text: result['transcription'], last_response: result }.to_json
      annotation.skip_check_ability = true
      annotation.save!
      completed = true
    elsif result['job_status'] == 'DONE'
      completed = true
    end
    self.delay_for(10.seconds, retry: 5).update_audio_transcription(annotation.id, attempts + 1) if !completed && attempts < 200 # Maximum: ~5h of transcription
  end

  def self.transcribe_audio(pm)
    annotation = nil
    if pm.report_type == 'uploadedaudio' || pm.report_type == 'uploadedvideo'
      url = self.media_file_url(pm)
      job_name = Digest::MD5.hexdigest(URI(url).open.read)
      s3_url = url.gsub(/^https?:\/\/[^\/]+/, "s3://#{CheckConfig.get('storage_bucket')}")
      result = self.request('post', '/audio/transcription/', { url: s3_url, job_name: job_name })
      annotation = self.save_annotation(pm, 'transcription', { text: '', job_name: job_name, last_response: result }) if result
      # FIXME: Calculate schedule interval based on audio duration
      self.delay_for(10.seconds, retry: 5).update_audio_transcription(annotation.id, 1)
    end
    annotation
  end

  def self.media_file_url(pm)
    # FIXME Ugly hack to get a usable URL in docker-compose development environment.
    if pm.is_a?(TemporaryProjectMedia)
      url = pm.url
    else
      url = (ENV['RAILS_ENV'] != 'development' ? pm.media.file.file.public_url : "#{CheckConfig.get('storage_endpoint')}/#{CheckConfig.get('storage_bucket')}/#{pm.media.file.file.path}")
    end
    # FIXME: Another hack mostly for local development and CI environments... a way to expose media URLs as public URLs
    url = url.gsub(/^https?:\/\/[^\/]+/, CheckConfig.get('similarity_media_file_url_host')) unless CheckConfig.get('similarity_media_file_url_host').blank?
    url
  end

  def self.item_doc_id(object, field_name=nil)
    Base64.encode64(["check", object.class.to_s.underscore, object&.id, field_name].join("-")).strip.delete("\n").delete("=")
  end

  def self.decode_item_doc_id(doc_id)
    Base64.decode64(doc_id).split("-")
  end

  def self.team_has_alegre_bot_installed?(team_id)
    tbi = self.get_alegre_tbi(team_id)
    !tbi.nil?
  end

  def self.get_tbi_indexing_models(tbi)
    tbi.get_alegre_model_in_use || self.default_model
  end

  def self.indexing_models_to_use(pm)
    tbi = self.get_alegre_tbi(pm&.team_id)
    [tbi.nil? ? self.default_model : self.get_tbi_indexing_models(tbi)].flatten
  end

  def self.language_for_similarity(team_id)
    # get language from team settings (team bot instalation)
    tbi = self.get_alegre_tbi(team_id)
    tbi.nil? ? nil : tbi.get_language_for_similarity
  end

  def self.get_tbi_matching_models(tbi)
    tbi.get_text_similarity_model || self.default_matching_model
  end

  def self.matching_model_to_use(team_ids)
    models = []
    [team_ids].flatten.each do |team_id|
      tbi = self.get_alegre_tbi(team_id)
      model = (tbi.nil? ? self.default_matching_model : self.get_tbi_matching_models(tbi))
      models << model unless models.include?(model)
    end
    models = models.flatten
    models.size == 1 ? models[0] : models
  end

  def self.get_alegre_tbi(team_id)
    bot = BotUser.alegre_user
    tbi = TeamBotInstallation.find_by_team_id_and_user_id(team_id, bot&&bot.id)
    tbi
  end

  def self.extract_project_medias_from_context(search_result)
    # We currently have two cases of context:
    # - a straight hash with project_media_id
    # - an array of hashes, each with project_media_id
    context = self.get_context_from_image_or_text_response(search_result)
    model = self.get_model_from_image_or_text_response(search_result)
    pms = []
    if context.kind_of?(Array)
      context.each{ |c| pms.push(c.with_indifferent_access.dig('project_media_id')) }
    elsif context.kind_of?(Hash)
      pms.push(context.with_indifferent_access.dig('project_media_id'))
    end
    Hash[pms.flatten.collect{ |pm| [pm.to_i, {score: self.get_score_from_image_or_text_response(search_result), context: context, model: model}] }]
  end

  def self.get_context_from_image_or_text_response(search_result)
    self.get_source_key_from_image_or_text_response(search_result, 'context')
  end

  def self.get_model_from_image_or_text_response(search_result)
    self.get_source_key_from_image_or_text_response(search_result, 'model')
  end

  def self.get_source_key_from_image_or_text_response(search_result, source_key)
    search_result.dig('_source', source_key) || search_result.dig(source_key)
  end

  def self.get_score_from_image_or_text_response(search_result)
    (search_result.with_indifferent_access.dig('_score')||search_result.with_indifferent_access.dig('score'))
  end

  def self.build_context(team_id, fields = nil)
    context = { has_custom_id: true }
    context[:field] = fields unless [fields].flatten.compact.reject(&:blank?).empty?
    context[:team_id] = team_id unless team_id.blank?
    context
  end

  def self.return_prioritized_matches(pm_id_scores)
    # Examples for "pm_id_scores":
    # pm_id_scores = [ # Array
    #   { score: 0.75, context: { 'team_id' => 1, 'project_media_id' => 2, 'has_custom_id' => true, 'field' => 'original_title', 'temporary_media' => false }, model: Bot::Alegre::OPENAI_ADA_MODEL },
    #   { score: 0.85, context: { 'team_id' => 1, 'project_media_id' => 3, 'has_custom_id' => true, 'field' => 'original_title', 'temporary_media' => false }, model: Bot::Alegre::MEAN_TOKENS_MODEL }
    # ]
    # pm_id_scores = { # Hash
    #   2 => {
    #     score: 0.75,
    #     context: { 'has_custom_id' => true, 'field' => 'original_description', 'project_media_id' => 2, 'temporary_media' => false, 'team_id' => 1 },
    #     model: Bot::Alegre::OPENAI_ADA_MODEL,
    #     source_field: 'original_description',
    #     target_field: 'original_description',
    #     relationship_type: { source: 'confirmed_sibling', target: 'confirmed_sibling' }
    #   },
    #   3 => {
    #     score: 0.85,
    #     context: { 'has_custom_id' => true, 'field' => 'original_description', 'project_media_id' => 3, 'temporary_media' => false, 'team_id' => 1 },
    #     model: Bot::Alegre::MEAN_TOKENS_MODEL,
    #     source_field: 'original_description',
    #     target_field: 'original_description',
    #     relationship_type: { source: 'confirmed_sibling', target: 'confirmed_sibling' }
    #   }
    # }
    if pm_id_scores.is_a?(Hash)
      # Make K negative so that we bias towards older IDs
      pm_id_scores.sort_by{ |k,v| [Bot::Alegre::TEXT_MODEL_RANKS.fetch(v[:model], 1), v[:score], -k] }.reverse
    elsif pm_id_scores.is_a?(Array)
      pm_id_scores.sort_by{ |v| [Bot::Alegre::TEXT_MODEL_RANKS.fetch(v[:model], 1), v[:score]] }.reverse
    else
      Rails.logger.error("[Alegre Bot] Unknown variable type in return_prioritized_matches: ##{pm_id_scores.class}")
      pm_id_scores
    end
  end

  def self.add_relationships(pm, pm_id_scores)
    # Evalute the scores of (possible) matches to existing ProjectMedia and determine the best represetation to store.
    # Clusters of similar PM are represented by storing links between each member item to a single representative 'parent' PM.
    # When new relationships are proposed to 'children' in a cluster, they may be re-represented as a link to the 'parent'
    # but the original proposal is also stored.

    # Relationships can have types 'suggested' or 'confirmed' depending on scores.
    # When a newly proposed relationship to a 'child' is stronger than the child's previous link to its parent,
    # the old relationship may be removed to form a new cluster.

    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 1/6] Adding relationships for #{pm_id_scores.inspect}"
    return if pm_id_scores.blank? || pm_id_scores.keys.include?(pm.id)

    # determine if there are any proposed matches
    # take first match as being the best potential parent.
    # Conditions to check for a valid parent in 2-level hierarchy:
    # - If it's a child, get its parent.
    # - If it's a parent, use it.
    # - If it has no existing relationship, use it.
    # make K negative so that we bias towards older IDs
    proposed_id = self.return_prioritized_matches(pm_id_scores).first.first

    # determine if the proposed id has any pre-existing relationships
    parent_relationships = Relationship.where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).where(target_id: proposed_id).all
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 2/6] Number of parent relationships #{parent_relationships.count}"
    parent_id = nil
    original_parent_id = nil
    original_relationship = nil

    if parent_relationships.length > 0
      # There will be at maximum one parent, because there is a unique index for the target_id column.
      # Take the first source as the parent (A).
      # 1. A is confirmed to B and C is suggested to B: type of the relationship between A and C is: suggested to A
      # 2. A is confirmed to B and C is confirmed to B: type of the relationship between A and C is: confirmed to A
      # 3. A is suggested to B and C is suggested to B: type of the relationship between A and C is: IGNORE (don't suggest to suggest)
      # 4. A is suggested to B and C is confirmed to B: type of the relationship between A and C is: form new relationship to B, break old relation to A
      parent_relationship = parent_relationships.first
      proposed_relationship_is_confirmed = pm_id_scores[proposed_id][:relationship_type] == Relationship.confirmed_type
      new_type = Relationship.suggested_type

      # (3) if relationship to parent was suggested, and new relationship is also suggested
      # we don't want to record this any more https://meedan.atlassian.net/browse/CV2-2675
      if !parent_relationship.is_confirmed? & !proposed_relationship_is_confirmed
        Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 3/6] [Relationships WARNING] ignoring suggested relationship pm_id, pm_id_scores, parent_id #{
          [pm.id, pm_id_scores, proposed_id].inspect}"
        return nil
      end

      # (1,2) relationships look great, but the proposed match should be replaced by a match to its parent
      if parent_relationship.is_confirmed?
        if proposed_relationship_is_confirmed
          new_type = Relationship.confirmed_type
        end
        original_parent_id = proposed_id
        parent_id = parent_relationship.source_id
        original_relationship = pm_id_scores[original_parent_id]
        pm_id_scores[parent_id] = pm_id_scores[original_parent_id]
        pm_id_scores[parent_id][:relationship_type] = new_type if pm_id_scores[parent_id]
      end

      # (4) if the relationship to parent was only suggested, but new relationship is confirmed
      if !parent_relationship.is_confirmed? & proposed_relationship_is_confirmed
        # break the old parent relationship involving proposed_id, make the proposed_id into a new parent
        Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 3/6] [Relationships NOTE] removing suggested relationship pm_id, parent_id #{
          [parent_relationship.source_id, parent_relationship.target_id].inspect}"
        parent_relationship.destroy!
        parent_id = proposed_id
      end

    else
      # the proposed match has no previous relationships, so we accept it as a parent
      parent_id = proposed_id
    end
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 3/6] Adding relationship for following pm_id, pm_id_scores, parent_id #{[pm.id, pm_id_scores, parent_id].inspect}"
    self.add_relationship(pm, pm_id_scores, parent_id, original_parent_id, original_relationship)
  end

  def self.add_relationship(pm, pm_id_scores, parent_id, original_parent_id=nil, original_relationship=nil)
    # Better be safe than sorry.
    return nil if parent_id == pm.id
    parent = ProjectMedia.find_by_id(parent_id)
    original_parent = ProjectMedia.find_by_id(original_parent_id)
    return nil if parent.nil?
    if parent.is_blank?
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 4/6] Parent is blank, creating suggested relationship"
      self.create_relationship(parent, pm, pm_id_scores, Relationship.suggested_type, original_parent, original_relationship)
    elsif pm_id_scores[parent_id]
      relationship_type = self.set_relationship_type(pm, pm_id_scores, parent)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 4/6] Creating relationship of #{relationship_type.inspect}"
      self.create_relationship(parent, pm, pm_id_scores, relationship_type, original_parent, original_relationship)
    end
  end

  def self.get_indexing_model(pm, score_with_context)
    score_with_context[:model] || self.get_pm_type(pm)
  end

  def self.is_suggested_to_trash(source, target, relationship_type)
    relationship_type == Relationship.suggested_type && (source.archived == CheckArchivedFlags::FlagCodes::TRASHED || target.archived == CheckArchivedFlags::FlagCodes::TRASHED)
  end

  def self.create_relationship(source, target, pm_id_scores, relationship_type, original_source=nil, original_relationship_type=nil)
    return nil if source&.id == target&.id || !self.can_create_relationship?(source, target, relationship_type)
    r = Relationship.where(source_id: source.id, target_id: target.id)
    .where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).last
    if r.nil?
      # Ensure that target relationship is confirmed before creating the relation `CHECK-907`
      if target.archived != CheckArchivedFlags::FlagCodes::NONE
        target.archived = CheckArchivedFlags::FlagCodes::NONE
        target.save!
      end
      r = self.fill_in_new_relationship(source, target, pm_id_scores, relationship_type, original_source, original_relationship_type)
      self.report_exception_if_bad_relationship(r, pm_id_scores, relationship_type) unless r.nil?
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{target.id}] [Relationships 5/6] Created new relationship for relationship ID of '#{r&.id}'"
    elsif self.is_relationship_upgrade?(r, relationship_type)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{target.id}] [Relationships 5/6] Upgrading relationship from suggested to confirmed for relationship ID of '#{r.id}'"
      # confirm existing relation if a new one is confirmed
      r.relationship_type = relationship_type
      r.save!
    end
    self.send_post_create_message(source, target, r)
    r
  end

  def self.is_relationship_upgrade?(relationship, relationship_type)
    relationship.relationship_type != relationship_type && relationship.relationship_type == Relationship.suggested_type
  end

  def self.fill_in_new_relationship(source, target, pm_id_scores, relationship_type, original_source, original_relationship_type)
    score_with_context = pm_id_scores[source.id] || {}
    options = {
      model: self.get_indexing_model(source, score_with_context),
      weight: score_with_context[:score],
      details: score_with_context[:context],
      source_field: score_with_context[:source_field],
      target_field: score_with_context[:target_field],
    }
    options.merge!({
      original_weight: pm_id_scores[original_source.id][:score],
      original_details: pm_id_scores[original_source.id][:context],
      original_relationship_type: original_relationship_type,
      original_model: self.get_indexing_model(original_source, pm_id_scores[original_source.id]),
      original_source_id: original_source.id,
      original_source_field: pm_id_scores[original_source.id][:source_field],
    }) if original_source
    options[:user_id] = BotUser.alegre_user&.id
    Relationship.create_unless_exists(source.id, target.id, relationship_type, options)
  end

  def self.can_create_relationship?(source, target, relationship_type)
    return false if source.nil? || target.nil?
    return false if self.is_suggested_to_trash(source, target, relationship_type)
    # Make sure that items imported from shared feed are not related automatically to anything,
    # since multiple medias can be imported at the same time, so the imported medias should form a cluster themselves
    return false if target.is_imported_from_shared_feed?
    return true
  end

  def self.send_post_create_message(source, target, relationship)
    return if relationship.nil?
    message_type = relationship.is_confirmed? ? 'related_to_confirmed_similar' : 'related_to_suggested_similar'
    message_opts = {item_title: target.title, similar_item_title: source.title}
    CheckNotification::InfoMessages.send(
      message_type,
      message_opts
    )
    Rails.logger.info "[Alegre Bot] [ProjectMedia ##{target.id}] [Relationships 6/6] Sent Check notification with message type and opts of #{[message_type, message_opts].inspect}"
  end

  def self.relationship_model_not_allowed(relationship_model)
    allowed_models = [MEAN_TOKENS_MODEL, INDIAN_MODEL, FILIPINO_MODEL, OPENAI_ADA_MODEL, PARAPHRASE_MULTILINGUAL_MODEL, ELASTICSEARCH_MODEL, 'audio', 'image', 'video']
    models = relationship_model.split("|").collect{ |m| m.split('/').first }
    models.length != (allowed_models&models).length
  end

  def self.report_exception_if_bad_relationship(relationship, pm_id_scores, relationship_type)
    if relationship.model.nil? || relationship.weight.nil? || relationship.source_field.nil? || relationship.target_field.nil? || self.relationship_model_not_allowed(relationship.model)
      CheckSentry.notify(Bot::Alegre::Error.new("[Alegre] Bad relationship with ID [#{relationship.id}] was stored without required metadata"), **{trace: Thread.current.backtrace.join("\n"), relationship: relationship.attributes, relationship_type: relationship_type, pm_id_scores: pm_id_scores})
    end
  end

  def self.set_relationship_type(pm, pm_id_scores, parent)
    tbi = self.get_alegre_tbi(pm&.team_id)
    settings = tbi.nil? ? {} : tbi.alegre_settings
    date_threshold = Time.now - settings['similarity_date_threshold'].to_i.months unless settings['similarity_date_threshold'].blank?
    relationship_type = pm_id_scores[parent.id][:relationship_type]
    if relationship_type != Relationship.suggested_type
      if settings['date_similarity_threshold_enabled'] && !date_threshold.blank? && parent.last_seen.to_i < date_threshold.to_i
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 6/6] Downgrading to suggestion due to parent age")
        relationship_type = Relationship.suggested_type
      else
        length_threshold = settings.blank? ? CheckConfig.get('text_length_matching_threshold').to_f : settings['text_length_matching_threshold'].to_f
        if self.is_text_too_short?(pm, length_threshold)
          Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Relationships 6/6] Downgrading to suggestion due short text")
          relationship_type = Relationship.suggested_type
        end
      end
    end
    relationship_type
  end

  def self.is_text_too_short?(pm, length_threshold)
    is_short = false
    unless pm.alegre_matched_fields.blank?
      fields_size = []
      pm.alegre_matched_fields.uniq.each do |field|
        fields_size << self.get_number_of_words(pm.send(field)) if pm.respond_to?(field)
      end
      is_short = fields_size.max < length_threshold unless fields_size.blank?
    end
    is_short
  end

end
