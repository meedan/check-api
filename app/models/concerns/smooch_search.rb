require 'active_support/concern'

module SmoochSearch
  extend ActiveSupport::Concern

  module ClassMethods

    # This method runs in background
    def search(app_id, uid, language, message, team_id, workflow, provider = nil)
      platform = self.get_platform_from_message(message)
      begin
        limit = CheckConfig.get('most_relevant_team_limit', 3, :integer)
        sm = CheckStateMachine.new(uid)
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        RequestStore.store[:smooch_bot_provider] = provider unless provider.blank?
        query = self.get_search_query(uid, message)
        results = self.get_search_results(uid, query, team_id, language, limit).collect{ |pm| Relationship.confirmed_parent(pm) }.uniq
        reports = results.select{ |pm| pm.report_status == 'published' }.collect{ |pm| pm.get_dynamic_annotation('report_design') }.reject{ |r| r.nil? }.collect{ |r| r.report_design_to_tipline_search_result }.select{ |r| r.should_send_in_language?(language) }

        # Extract explainers from matched media if they don't have published fact-checks but they have explainers
        reports = results.collect{ |pm| pm.explainers.to_a }.flatten.uniq.first(limit).map(&:as_tipline_search_result) if !results.empty? && reports.empty?

        # Search for explainers if fact-checks were not found
        if reports.empty? && query['type'] == 'text'
          explainers = self.search_for_explainers(uid, query['text'], team_id, limit, language).select{ |explainer| explainer.as_tipline_search_result.should_send_in_language?(language) }
          Rails.logger.info "[Smooch Bot] Text similarity search got #{explainers.count} explainers while looking for '#{query['text']}' for team #{team_id}"
          results = explainers.collect{ |explainer| explainer.project_medias.to_a }.flatten.uniq.reject{ |pm| pm.blank? }.first(limit)
          reports = explainers.map(&:as_tipline_search_result)
        end

        if reports.empty?
          self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
          self.send_final_message_to_user(uid, self.get_custom_string('search_no_results', language), workflow, language, 'no_results')
        else
          self.send_search_results_to_user(uid, reports, team_id, platform)
          sm.go_to_search_result
          self.save_search_results_for_user(uid, results.map(&:id))
          self.delay_for(1.second, { queue: 'smooch_priority' }).ask_for_feedback_when_all_search_results_are_received(app_id, language, workflow, uid, platform, provider, 1)
        end
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
    end

    def save_search_results_for_user(uid, pmids)
      Rails.cache.write("smooch:user_search_results:#{uid}", pmids, expires_in: 20.minutes) # Just need to be sure it's more than the 15 minutes of conversation timeout
    end

    def get_saved_search_results_for_user(uid)
      Rails.cache.read("smooch:user_search_results:#{uid}").to_a.collect{ |result_id| ProjectMedia.find(result_id) }
    end

    def handle_search_error(uid, e, _language)
      self.send_message_to_user(uid, 'Error')
      sm = CheckStateMachine.new(uid)
      sm.reset
      self.handle_exception(e)
    end

    def bundle_search_query(uid)
      list = self.list_of_bundled_messages_from_user(uid)
      self.clear_user_bundled_messages(uid)
      list
    end

    def submit_search_query_for_verification(uid, app_id, workflow, language)
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, '', app_id, 'irrelevant_search_result_requests', nil, true, self.bundle_search_query(uid))
      self.send_final_message_to_user(uid, self.get_custom_string('search_submit', language), workflow, language)
    end

    def ask_if_ready_to_submit(uid, workflow, state, language)
      self.send_message_for_state(uid, workflow, state, language)
    end

    def go_to_state_and_ask_if_ready_to_submit(uid, language, workflow)
      sm = CheckStateMachine.new(uid)
      sm.go_to_ask_if_ready unless sm.state.value == 'ask_if_ready'
      self.ask_if_ready_to_submit(uid, workflow, 'ask_if_ready', language)
    end

    def filter_search_results(pms, after, feed_id, team_ids, published_only)
      return [] if pms.empty?
      feed_results = []
      if feed_id && team_ids
        filters = { feed_id: feed_id, project_media_ids: pms.map(&:id) }
        filters.merge!({ range: { updated_at: { start_time: after.strftime('%Y-%m-%dT%H:%M:%S.%LZ') } } }) unless after.blank?
        feed_results = CheckSearch.new(filters.to_json, nil, team_ids).medias.to_a.map(&:id)
      end
      pms.compact_blank.select do |pm|
        (feed_id && feed_results.include?(pm.id)) || (!feed_id && pm.updated_at.to_i > after.to_i && is_a_valid_search_result(pm, published_only))
      end
    end

    def is_a_valid_search_result(pm, published_only)
      published_condition = (published_only ? pm.report_status == 'published' : true)
      (published_condition || pm.explainers.count > 0) && [CheckArchivedFlags::FlagCodes::NONE, CheckArchivedFlags::FlagCodes::UNCONFIRMED].include?(pm.archived)
    end

    def reject_temporary_results(results)
      results.select do |_, result_data|
        ![result_data[:context]].flatten.compact.select{|x| x[:temporary_media].nil? || x[:temporary_media] == false}.empty?
      end
    end

    def parse_search_results_from_alegre(results, limit, published_only, after = nil, feed_id = nil, team_ids = nil)
      # Example for "results":
      # results = {
      #   2 => {
      #     score: 0.75,
      #     context: { 'team_id' => 1, 'project_media_id' => 2, 'has_custom_id' => true, 'field' => 'claim_description_content|report_visual_card_title', 'temporary_media' => false, 'contexts_count' => 14 },
      #     model: Bot::Alegre::FILIPINO_MODEL
      #   },
      #   3 => {
      #     score: 0.85,
      #     context: { 'team_id' => 1, 'project_media_id' => 2, 'has_custom_id' => true, 'field' => 'claim_description_content|report_visual_card_title', 'temporary_media' => false, 'contexts_count' => 4 },
      #     model: Bot::Alegre::MEAN_TOKENS_MODEL
      #   }
      # }
      pms = Bot::Alegre.return_prioritized_matches(reject_temporary_results(results)).to_h.keys.collect { |id| Relationship.confirmed_parent(ProjectMedia.find_by_id(id)) }
      filter_search_results(pms, after, feed_id, team_ids, published_only).uniq(&:id).first(limit)
    end

    def date_filter(team_id)
      tbi = TeamBotInstallation.where(user_id: BotUser.alegre_user&.id, team_id: team_id).last
      settings = tbi.nil? ? {} : tbi.alegre_settings
      date = Time.now - settings['similarity_date_threshold'].to_i.months unless settings['similarity_date_threshold'].blank?
      settings['date_similarity_threshold_enabled'] && !date.blank? ? date : nil
    end

    def max_number_of_words_for_keyword_search
      value = self.config.to_h['smooch_search_max_keyword'].to_i
      value == 0 ? 3 : value
    end

    def get_text_similarity_threshold
      value = self.config.to_h['smooch_search_text_similarity_threshold'].to_f
      value == 0.0 ? 0.85 : value
    end

    def get_search_query(uid, last_message)
      list = self.list_of_bundled_messages_from_user(uid)
      self.bundle_list_of_messages(list, last_message, true)
    end

    def get_search_results(uid, message, team_id, language, limit, published_only = true)
      results = []
      begin
        type = message['type']
        after = self.date_filter(team_id)
        query = message['text']
        query = CheckS3.rewrite_url(message['mediaUrl']) unless type == 'text'
        results = self.search_for_similar_published_fact_checks(type, query, [team_id], limit, after, nil, language).select{ |pm| is_a_valid_search_result(pm, published_only) }
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
      results
    end

    def normalized_query_hash(type, query, team_ids, after, feed_id, language)
      normalized_query = query.downcase.chomp.strip unless query.nil?
      Digest::MD5.hexdigest([type.to_s, normalized_query, [team_ids].flatten.join(','), after.to_s, feed_id.to_i, language.to_s].join(':'))
    end

    # "type" is text, video, audio or image
    # "query" is either a piece of text of a media URL
    def search_for_similar_published_fact_checks(type, query, team_ids, limit, after = nil, feed_id = nil, language = nil, skip_cache = false)
      if skip_cache
        self.search_for_similar_published_fact_checks_no_cache(type, query, team_ids, limit, after, feed_id, language)
      else
        Rails.cache.fetch("smooch:search_results:#{self.normalized_query_hash(type, query, team_ids, after, feed_id, language)}", expires_in: 2.hours) do
          self.search_for_similar_published_fact_checks_no_cache(type, query, team_ids, limit, after, feed_id, language)
        end
      end
    end

    def get_setting_value_or_default(setting_name, custom_settings, team_ids = nil)
      custom_value = custom_settings.to_h.with_indifferent_access[setting_name]
      return custom_value unless custom_value.nil?
      case setting_name.to_sym
      when :threshold
        self.get_text_similarity_threshold
      when :max_number_of_words
        self.max_number_of_words_for_keyword_search
      when :should_restrict_by_language
        self.should_restrict_by_language?(team_ids)
      else
        nil
      end
    end

    # "type" is text, video, audio or image
    # "query" is either a piece of text of a media URL
    def search_for_similar_published_fact_checks_no_cache(type, query, team_ids, limit, after = nil, feed_id = nil, language = nil, published_only = true, settings = nil)
      results = []
      pm = nil
      pm = ProjectMedia.new(team_id: team_ids[0]) if team_ids.size == 1 # We'll use the settings of a team instead of global settings when there is only one team
      if type == 'text'
        link = self.extract_url(query)
        text = ::Bot::Smooch.extract_claim(query)
        unless link.nil?
          Rails.logger.info "[Smooch Bot] Search query (URL): #{link.url}"
          pms = ProjectMedia.joins(:media).where('medias.url' => link.url, 'project_medias.team_id' => team_ids).to_a
          result = self.filter_search_results(pms, after, feed_id, team_ids, published_only)
          return result unless result.empty?
          text = [link.pender_data['description'].to_s, text.to_s.gsub(/https?:\/\/[^\s]+/, '').strip].max_by(&:length)
        end
        return [] if text.blank?
        text = self.remove_meaningless_phrases(text)
        words = text.split(/\s+/)
        Rails.logger.info "[Smooch Bot] Search query (text): #{text}"
        if Bot::Alegre.get_number_of_words(text) <= self.get_setting_value_or_default('max_number_of_words', settings)
          results = self.search_by_keywords_for_similar_published_fact_checks(words, after, team_ids, limit, feed_id, language, published_only, settings)
        else
          alegre_results = Bot::Alegre.get_merged_similar_items(pm, [{ value: self.get_setting_value_or_default('threshold', settings) }], Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, text, team_ids)
          results = self.parse_search_results_from_alegre(alegre_results, limit, published_only, after, feed_id, team_ids)
          Rails.logger.info "[Smooch Bot] Text similarity search got #{results.count} results while looking for '#{text}' after date #{after.inspect} for teams #{team_ids}"
        end
      else
        media_url = Twitter::TwitterText::Extractor.extract_urls(query)[0]
        Rails.logger.info "[Smooch Bot] Got media_url #{media_url} from query #{query}"
        return [] if media_url.blank?
        media_url = self.save_locally_and_return_url(media_url, type, feed_id)
        threshold = Bot::Alegre.get_threshold_for_query(type, pm)[0][:value]
        alegre_results = Bot::Alegre.get_items_with_similar_media_v2(media_url: media_url, threshold: [{ value: threshold }], team_ids: team_ids, type: type)
        results = self.parse_search_results_from_alegre(alegre_results, limit, published_only, after, feed_id, team_ids)
        Rails.logger.info "[Smooch Bot] Media similarity search got #{results.count} results while looking for '#{query}' after date #{after.inspect} for teams #{team_ids}"
      end
      results
    end

    def remove_meaningless_phrases(text)
      redis = Redis.new(REDIS_CONFIG)
      meaningless_phrases = JSON.parse(redis.get("smooch_search_meaningless_phrases") || "[]")
      meaningless_phrases.each{|phrase| text.sub!(/^#{phrase}\W/i,'')}
      text.strip!()
      text
    end

    def save_locally_and_return_url(media_url, type, feed_id)
      feed = Feed.find_by_id(feed_id.to_i)
      return media_url if feed.nil?
      headers = feed.get_media_headers.to_h
      return media_url if headers.blank?
      mime = {
        image: 'image/jpeg',
        audio: 'audio/ogg',
        video: 'video/mp4'
      }[type.to_sym]
      path = "feed/#{feed.id}/#{SecureRandom.hex}"
      self.write_file_to_s3(
        media_url,
        path,
        mime,
        headers
      )
    end

    def write_file_to_s3(media_url, path, mime, headers)
      uri = URI(media_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      req = Net::HTTP::Get.new(uri.request_uri, headers)
      response = http.request(req)
      body = response.body
      CheckS3.write(path, mime, body)
      Rails.cache.write("url_sha:#{media_url}", Digest::MD5.hexdigest(body), expires_in: 60*3)
      CheckS3.public_url(path)
    end

    def should_restrict_by_language?(team_ids)
      return false if team_ids.size > 1
      team = Team.find(team_ids[0])
      return false if team.get_languages.to_a.size < 2
      tbi = TeamBotInstallation.where(team_id: team.id, user: BotUser.alegre_user).last
      !!tbi&.alegre_settings&.dig('single_language_fact_checks_enabled')
    end

    def search_by_keywords_for_similar_published_fact_checks(words, after, team_ids, limit, feed_id = nil, language = nil, published_only = true, settings = nil)
      types = CheckSearch::MEDIA_TYPES.clone.push('blank')
      search_fields = %w(title description fact_check_title fact_check_summary extracted_text url claim_description_content)
      filters = { keyword: words.join('+'), keyword_fields: { fields: search_fields }, sort: 'recent_activity', eslimit: limit, show: types }
      filters.merge!({ fc_language: [language] }) if !language.blank? && self.get_setting_value_or_default(:should_restrict_by_language, settings, team_ids)
      filters.merge!({ sort: 'score' }) if words.size > 1 # We still want to be able to return the latest fact-checks if a meaninful query is not passed
      if feed_id.blank?
        filters.merge!({ report_status: ['published'] }) if published_only
      else
        filters.merge!({ feed_id: feed_id })
      end
      filters.merge!({ range: { updated_at: { start_time: after.strftime('%Y-%m-%dT%H:%M:%S.%LZ') } } }) unless after.blank?
      results = CheckSearch.new(filters.to_json, nil, team_ids).medias
      Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results (only main items) while looking for '#{words}' after date #{after.inspect} for teams #{team_ids}"
      if results.empty? and not words.join().gsub(/\P{L}/u, ' ').strip().blank?
        results = CheckSearch.new(filters.merge({ keyword: words.collect{ |w| w =~ /^\P{L}$/u ? "+#{w}" : "+#{w}~1" }.join(' '), show_similar: true }).to_json, nil, team_ids).medias
        Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results (including secondary items and using fuzzy matching) while looking for '#{words}' after date #{after.inspect} for teams #{team_ids}"
      end
      results
    end

    def send_search_results_to_user(uid, reports, team_id, platform)
      team = Team.find(team_id)
      redis = Redis.new(REDIS_CONFIG)
      language = self.get_user_language(uid)
      reports_languages = reports.map(&:language).uniq

      if team.get_languages.to_a.size > 1 && !reports_languages.include?(language)
        self.send_message_to_user(uid, self.get_string(:no_results_in_language, language).gsub('%{language}', CheckCldr.language_code_to_name(language, language)), {}, false, true, 'no_results')
        sleep 1
      end

      reports.each do |report|
        response = nil
        no_body = (platform == 'Facebook Messenger' && !report.url.blank?)
        response = self.send_message_to_user(uid, report.text(nil, no_body), {}, false, true, 'search_result') if report.format == :text
        response = self.send_message_to_user(uid, '', { 'type' => 'image', 'mediaUrl' => report.image_url }, false, true, 'search_result') if report.format == :image
        id = self.get_id_from_send_response(response)
        redis.rpush("smooch:search:#{uid}", id) unless id.blank?
      end
    end

    def send_explainer_to_user(ex_item_id, tipline_request_id)
      tipline_request = TiplineRequest.find_by_id(tipline_request_id.to_i)
      report = ExplainerItem.find_by_id(ex_item_id.to_i)&.explainer&.as_tipline_search_result
      return if tipline_request.nil? || report.nil?
      data = tipline_request.smooch_data
      uid = tipline_request.tipline_user_uid
      self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
      no_body = (tipline_request.platform == 'Facebook Messenger' && !report.url.blank?)
      Rails.logger.info "[Smooch Bot] Sending explainer report to user #{uid} for ExplainerItem with ID #{ex_item_id}..."
      last_smooch_response = self.send_message_to_user(uid, report.text(nil, no_body), {}, false, true, 'report')
      # FIXME: We should rename the WhatsApp template "fact_check_report" to "article_report"
      self.save_smooch_response(last_smooch_response, tipline_request.associated, data['received'], 'fact_check_report', tipline_request.language, { explainer_item_id: ex_item_id })
      # Set smooch_report_sent_at to Time.now to prevent re-sending for the same request
      tipline_request.update_column(:smooch_report_sent_at, Time.now.to_i) if last_smooch_response.present?
    end

    def user_received_search_result(message)
      uid = message['appUser']['_id']
      id = message['message']['_id']
      redis = Redis.new(REDIS_CONFIG)
      redis.lrem("smooch:search:#{uid}", 0, id) if redis.exists("smooch:search:#{uid}") == 1
    end

    def ask_for_feedback_when_all_search_results_are_received(app_id, language, workflow, uid, platform, provider, attempts)
      RequestStore.store[:smooch_bot_platform] = platform
      redis = Redis.new(REDIS_CONFIG)
      max = 20
      if redis.llen("smooch:search:#{uid}") == 0 && CheckStateMachine.new(uid).state.value == 'search_result'
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        RequestStore.store[:smooch_bot_provider] = provider unless provider.blank?
        self.send_message_for_state(uid, workflow, 'search_result', language)
      else
        redis.del("smooch:search:#{uid}") if (attempts + 1) == max # Give up and just ask for feedback on the last iteration
        self.delay_for(1.second, { queue: 'smooch_priority' }).ask_for_feedback_when_all_search_results_are_received(app_id, language, workflow, uid, platform, provider, attempts + 1) if attempts < max # Try for 20 seconds
      end
    end

    def search_for_explainers(uid, query, team_id, limit, language = nil, settings = nil)
      results = nil
      begin
        text = ::Bot::Smooch.extract_claim(query)
        if Bot::Alegre.get_number_of_words(text) == 1
          results = Explainer.where(team_id: team_id).where('description ILIKE ? OR title ILIKE ?', "%#{text}%", "%#{text}%")
          results = results.where(language: language) if !language.nil? && self.get_setting_value_or_default(:should_restrict_by_language, settings, [team_id])
          results = results.order('updated_at DESC')
        else
          results = Explainer.search_by_similarity(text, language, team_id, limit, settings.to_h.with_indifferent_access[:threshold])
        end
      rescue StandardError => e
        self.handle_search_error(uid, e, language) unless uid.blank?
      end
      results.joins(:project_medias)
    end
  end
end
