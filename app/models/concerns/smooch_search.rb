require 'active_support/concern'

module SmoochSearch
  extend ActiveSupport::Concern

  module ClassMethods
    # This method runs in background
    def search(app_id, uid, language, message, team_id, workflow)
      begin
        sm = CheckStateMachine.new(uid)
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        results = self.get_search_results(uid, message, team_id, language)
        if results.empty?
          self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
          self.send_final_message_to_user(uid, self.get_menu_string('search_no_results', language), workflow, language)
        else
          self.send_message_to_user(uid, self.format_search_results(results))
          sm.go_to_search_result
          self.send_message_for_state(uid, workflow, 'search_result', language)
        end
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
    end

    def handle_search_error(uid, e, language)
      self.send_message_to_user(uid, self.get_menu_string('search_error', language))
      sm = CheckStateMachine.new(uid)
      sm.reset
      self.handle_exception(e)
    end

    def submit_search_query_for_verification(uid, app_id, workflow, language)
      self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
      self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
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

    def parse_search_results_from_alegre(results, team_id)
      after = self.date_filter(team_id)
      results.sort{ |a, b| a[1][:score] <=> b[1][:score] }.to_h.keys.reverse.collect{ |id| ProjectMedia.find(id) }.select{ |pm| pm.report_status == 'published' && pm.updated_at.to_i > after.to_i && !pm.analysis_published_article_url.blank? }.last(3)
    end

    def date_filter(team_id)
      tbi = TeamBotInstallation.where(user_id: BotUser.alegre_user&.id, team_id: team_id).last
      settings = tbi.nil? ? {} : tbi.alegre_settings
      date = Time.now - settings['similarity_date_threshold'].to_i.months unless settings['similarity_date_threshold'].blank?
      settings['date_similarity_threshold_enabled'] && !date.blank? ? date : nil
    end

    def get_search_results(uid, last_message, team_id, language)
      results = []
      begin
        list = self.list_of_bundled_messages_from_user(uid)
        message = self.bundle_list_of_messages(list, last_message)
        type = message['type'] || 'text'
        after = self.date_filter(team_id)
        if type == 'text'
          words = ::Bot::Smooch.extract_claim(message['text']).split(/\s+/)
          text = words.join(' ')
          if words.size <= 3
            filters = { keyword: text, eslimit: 3, report_status: ['published'] }
            filters.merge!({ range: { updated_at: { start_time: after.strftime('%Y-%m-%dT%H:%M:%S.%LZ') } } }) if after
            results = CheckSearch.new(filters.to_json, nil, team_id).medias
            Rails.logger.info "[Smooch Bot] Keyword search got #{results.count} results while looking for '#{text}' after date #{after.inspect} for team #{team_id}"
          else
            results = self.parse_search_results_from_alegre(Bot::Alegre.get_similar_texts([team_id], text), team_id)
            Rails.logger.info "[Smooch Bot] Text similarity search got #{results.count} results while looking for '#{text}' after date #{after.inspect} for team #{team_id}"
          end
        else
          threshold = Bot::Alegre.get_threshold_for_query(type, ProjectMedia.new(team_id: team_id))[:value]
          results = self.parse_search_results_from_alegre(Bot::Alegre.get_items_with_similar_media(message['mediaUrl'], { value: threshold }, [team_id], "/#{type}/similarity/"), team_id)
          Rails.logger.info "[Smooch Bot] Media similarity search got #{results.count} results while looking for '#{message['mediaUrl']}' after date #{after.inspect} for team #{team_id}"
        end
      rescue StandardError => e
        self.handle_search_error(uid, e, language)
      end
      results
    end

    def format_search_results(results)
      results.collect{ |r| "#{r.title}\n#{r.analysis_published_article_url}" }.join("\n\n")
    end
  end
end
