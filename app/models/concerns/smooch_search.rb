require 'active_support/concern'

module SmoochSearch
  extend ActiveSupport::Concern

  module ClassMethods
    # This method runs in background
    def search(app_id, uid, language, message, team_id, workflow)
      platform = self.get_platform_from_message(message)
      begin
        sm = CheckStateMachine.new(uid)
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        results = self.get_search_results(uid, message, team_id, language)
        if results.empty?
          self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
          self.send_final_message_to_user(uid, self.get_menu_string('search_no_results', language), workflow, language)
        else
          self.send_search_results_to_user(uid, results)
          sm.go_to_search_result
          self.save_search_results_for_user(uid, results.map(&:id))
          self.delay_for(1.second, { queue: 'smooch_priority' }).ask_for_feedback_when_all_search_results_are_received(app_id, language, workflow, uid, platform, 1)
        end
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
    end

    def save_search_results_for_user(uid, pmids)
      Rails.cache.write("smooch:user_search_results:#{uid}", pmids)
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
      self.send_final_message_to_user(uid, self.get_menu_string('search_submit', language), workflow, language)
    end

    def ask_if_ready_to_submit(uid, workflow, state, language)
      self.send_message_for_state(uid, workflow, state, language)
    end

    def go_to_state_and_ask_if_ready_to_submit(uid, language, workflow)
      sm = CheckStateMachine.new(uid)
      sm.go_to_ask_if_ready unless sm.state.value == 'ask_if_ready'
      self.ask_if_ready_to_submit(uid, workflow, 'ask_if_ready', language)
    end

    def filter_search_results(pms, after, feed_id, team_ids)
      return [] if pms.empty?
      feed_results = []
      if feed_id && team_ids
        filters = { feed_id: feed_id, project_media_ids: pms.map(&:id) }
        filters.merge!({ range: { updated_at: { start_time: after.strftime('%Y-%m-%dT%H:%M:%S.%LZ') } } }) unless after.blank?
        feed_results = CheckSearch.new(filters.to_json, nil, team_ids).medias.to_a.map(&:id)
      end
      pms.select do |pm|
        (feed_id && feed_results.include?(pm&.id)) || (!feed_id && pm&.report_status == 'published' && pm&.updated_at.to_i > after.to_i)
      end
    end

    def parse_search_results_from_alegre(results, after = nil, feed_id = nil, team_ids = nil)
      pms = results.sort_by{ |a| [a[1][:model] != Bot::Alegre::ELASTICSEARCH_MODEL ? 1 : 0, a[1][:score]] }.to_h.keys.reverse.collect{ |id| Relationship.confirmed_parent(ProjectMedia.find_by_id(id)) }
      filter_search_results(pms, after, feed_id, team_ids).uniq(&:id).first(3)
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

    def get_search_results(uid, last_message, team_id, language)
      results = []
      begin
        list = self.list_of_bundled_messages_from_user(uid)
        message = self.bundle_list_of_messages(list, last_message, true)
        type = message['type']
        after = self.date_filter(team_id)
        query = message['text']
        query = message['mediaUrl'] unless type == 'text'
        results = self.search_for_similar_published_fact_checks(type, query, [team_id], after)
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
      results
    end

    def normalized_query_hash(type, query, team_ids, after, feed_id)
      normalized_query = query.downcase.chomp.strip
      Digest::MD5.hexdigest([type.to_s, normalized_query, [team_ids].flatten.join(','), after.to_s, feed_id.to_i].join(':'))
    end

    # "type" is text, video, audio or image
    # "query" is either a piece of text of a media URL
    def search_for_similar_published_fact_checks(type, query, team_ids, after = nil, feed_id = nil)
      Rails.cache.fetch("smooch:search_results:#{self.normalized_query_hash(type, query, team_ids, after, feed_id)}", expires_in: 2.hours) do
        self.search_for_similar_published_fact_checks_no_cache(type, query, team_ids, after, feed_id)
      end
    end

    # "type" is text, video, audio or image
    # "query" is either a piece of text of a media URL
    def search_for_similar_published_fact_checks_no_cache(type, query, team_ids, after = nil, feed_id = nil)
      results = []
      pm = nil
      pm = ProjectMedia.new(team_id: team_ids[0]) if team_ids.size == 1 # We'll use the settings of a team instead of global settings when there is only one team
      if type == 'text'
        link = self.extract_url(query)
        text = ::Bot::Smooch.extract_claim(query)
        unless link.nil?
          Rails.logger.info "[Smooch Bot] Search query (URL): #{link.url}"
          pms = ProjectMedia.joins(:media).where('medias.url' => link.url, 'project_medias.team_id' => team_ids).to_a
          result = self.filter_search_results(pms, after, feed_id, team_ids)
          return result unless result.empty?
          text = [link.pender_data['description'].to_s, text.to_s.gsub(/https?:\/\/[^\s]+/, '').strip].max_by(&:length)
        end
        return [] if text.blank?
        words = text.split(/\s+/)
        Rails.logger.info "[Smooch Bot] Search query (text): #{text}"
        if words.size <= self.max_number_of_words_for_keyword_search
          results = self.search_by_keywords_for_similar_published_fact_checks(words, after, team_ids, feed_id)
        else
          alegre_results = Bot::Alegre.get_merged_similar_items(pm, { value: self.get_text_similarity_threshold }, Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, text, team_ids)
          results = self.parse_search_results_from_alegre(alegre_results, after, feed_id, team_ids)
          Rails.logger.info "[Smooch Bot] Text similarity search got #{results.count} results while looking for '#{text}' after date #{after.inspect} for teams #{team_ids}"
        end
      else
        threshold = Bot::Alegre.get_threshold_for_query(type, pm)[:value]
        alegre_results = Bot::Alegre.get_items_with_similar_media(query, { value: threshold }, team_ids, "/#{type}/similarity/")
        results = self.parse_search_results_from_alegre(alegre_results, after, feed_id, team_ids)
        Rails.logger.info "[Smooch Bot] Media similarity search got #{results.count} results while looking for '#{query}' after date #{after.inspect} for teams #{team_ids}"
      end
      results
    end

    def search_by_keywords_for_similar_published_fact_checks(words, after, team_ids, feed_id = nil)
      filters = { keyword: words.join('+'), eslimit: 3 }
      filters.merge!({ sort: 'score' }) if words.size > 1 # We still want to be able to return the latest fact-checks if a meaninful query is not passed
      feed_id.blank? ? filters.merge!({ report_status: ['published'] }) : filters.merge!({ feed_id: feed_id })
      filters.merge!({ range: { updated_at: { start_time: after.strftime('%Y-%m-%dT%H:%M:%S.%LZ') } } }) unless after.blank?
      results = CheckSearch.new(filters.to_json, nil, team_ids).medias
      Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results (only main items) while looking for '#{words}' after date #{after.inspect} for teams #{team_ids}"
      results = CheckSearch.new(filters.merge({ show_similar: true, fuzzy: true }).to_json, nil, team_ids).medias if results.empty?
      Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results (including secondary items and using fuzzy matching) while looking for '#{words}' after date #{after.inspect} for teams #{team_ids}"
      results
    end

    def send_search_results_to_user(uid, results)
      redis = Redis.new(REDIS_CONFIG)
      results = results.collect { |r| Relationship.confirmed_parent(r) }.uniq
      results.each do |result|
        report = result.get_dynamic_annotation('report_design')
        response = nil
        response = self.send_message_to_user(uid, '', { 'type' => 'image', 'mediaUrl' => report&.report_design_image_url }) if report && report.report_design_field_value('use_visual_card')
        response = self.send_message_to_user(uid, report.report_design_text) if report && !report.report_design_field_value('use_visual_card') && report.report_design_field_value('use_text_message')
        id = self.get_id_from_send_response(response)
        redis.rpush("smooch:search:#{uid}", id) unless id.blank?
      end
    end

    def user_received_search_result(message)
      uid = message['appUser']['_id']
      id = message['message']['_id']
      redis = Redis.new(REDIS_CONFIG)
      redis.lrem("smooch:search:#{uid}", 0, id) if redis.exists("smooch:search:#{uid}") == 1
    end

    def ask_for_feedback_when_all_search_results_are_received(app_id, language, workflow, uid, platform, attempts)
      RequestStore.store[:smooch_bot_platform] = platform
      redis = Redis.new(REDIS_CONFIG)
      if redis.llen("smooch:search:#{uid}") == 0 && CheckStateMachine.new(uid).state.value == 'search_result'
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        self.send_message_for_state(uid, workflow, 'search_result', language)
      else
        self.delay_for(1.second, { queue: 'smooch_priority' }).ask_for_feedback_when_all_search_results_are_received(app_id, language, workflow, uid, platform, attempts + 1) if attempts < 30 # Try for 30 seconds
      end
    end
  end
end
