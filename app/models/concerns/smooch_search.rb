require 'active_support/concern'

module SmoochSearch
  extend ActiveSupport::Concern

  module ClassMethods
    # This method runs in background
    def search(app_id, uid, language, message, team_id, workflow)
      begin
        self.get_platform_from_message(message)
        sm = CheckStateMachine.new(uid)
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        results = self.get_search_results(uid, message, team_id, language)
        if results.empty?
          self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
          self.send_final_message_to_user(uid, self.get_menu_string('search_no_results', language), workflow, language)
        else
          self.send_message_to_user(uid, self.format_search_results(results))
          sm.go_to_search_result
          self.save_search_results_for_user(uid, results.map(&:id))
          self.send_message_for_state(uid, workflow, 'search_result', language)
        end
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
    end

    def save_search_results_for_user(uid, pmids)
      Rails.cache.write("smooch:user_search_results:#{uid}", pmids)
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
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, '', app_id, 'default_requests', nil, true, self.bundle_search_query(uid))
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

    def parse_search_results_from_alegre(results, after = nil)
      results.sort_by{ |a| [a[1][:model] != Bot::Alegre::ELASTICSEARCH_MODEL ? 1 : 0, a[1][:score]] }.to_h.keys.reverse.collect{ |id| Relationship.confirmed_parent(ProjectMedia.find_by_id(id)) }.select{ |pm| pm&.report_status == 'published' && pm&.updated_at.to_i > after.to_i }.uniq(&:id).first(3)
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
      value == 0.0 ? 0.9 : value
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

    # "type" is text, video, audio or image
    # "query" is either a piece of text of a media URL
    def search_for_similar_published_fact_checks(type, query, team_ids, after = nil)
      results = []
      pm = nil
      pm = ProjectMedia.new(team_id: team_ids[0]) if team_ids.size == 1 # We'll use the settings of a team instead of global settings when there is only one team
      if type == 'text'
        link = self.extract_url(query)
        text = ::Bot::Smooch.extract_claim(query)
        unless link.nil?
          Rails.logger.info "[Smooch Bot] Search query (URL): #{link.url}"
          result = ProjectMedia.joins(:media).where('medias.url' => link.url, 'project_medias.team_id' => team_ids).last
          return [result] if result&.report_status == 'published'
          text = link.pender_data['description']
        end
        words = text.split(/\s+/)
        Rails.logger.info "[Smooch Bot] Search query (text): #{text}"
        if words.size <= self.max_number_of_words_for_keyword_search
          filters = { keyword: words.join('+'), eslimit: 3, report_status: ['published'] }
          filters.merge!({ range: { updated_at: { start_time: after.strftime('%Y-%m-%dT%H:%M:%S.%LZ') } } }) if after
          results = CheckSearch.new(filters.to_json, nil, team_ids).medias
          Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results (only main items) while looking for '#{text}' after date #{after.inspect} for teams #{team_ids}"
          results = CheckSearch.new(filters.merge({ show_similar: true }).to_json, nil, team_ids).medias if results.empty?
          Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results (including secondary items) while looking for '#{text}' after date #{after.inspect} for teams #{team_ids}"
        else
          alegre_results = Bot::Alegre.get_merged_similar_items(pm, { value: self.get_text_similarity_threshold }, Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, text, team_ids)
          results = self.parse_search_results_from_alegre(alegre_results, after)
          Rails.logger.info "[Smooch Bot] Text similarity search got #{results.count} results while looking for '#{text}' after date #{after.inspect} for teams #{team_ids}"
        end
      else
        threshold = Bot::Alegre.get_threshold_for_query(type, pm)[:value]
        alegre_results = Bot::Alegre.get_items_with_similar_media(query, { value: threshold }, team_ids, "/#{type}/similarity/")
        results = self.parse_search_results_from_alegre(alegre_results, after)
        Rails.logger.info "[Smooch Bot] Media similarity search got #{results.count} results while looking for '#{query}' after date #{after.inspect} for teams #{team_ids}"
      end
      results
    end

    def format_search_results(results)
      results = results.collect { |r| Relationship.confirmed_parent(r) }.uniq
      results.collect do |r|
        title = r.fact_check_title || r.report_text_title || r.title
        "#{title}\n#{r.published_url}"
      end.join("\n\n")
    end
  end
end
