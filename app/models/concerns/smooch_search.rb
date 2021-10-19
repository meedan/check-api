require 'active_support/concern'

module SmoochSearch
  extend ActiveSupport::Concern

  module ClassMethods
    # This method runs in background
    def search(app_id, uid, language, message, team_id)
      begin
        sm = CheckStateMachine.new(uid)
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        results = self.get_search_results(uid, message, team_id)
        if results.empty?
          self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
          self.send_message_to_user(uid, I18n.t(:smooch_v2_search_no_results))
        else
          self.send_message_to_user(uid, self.format_search_results(results))
          sm.go_to_search_result
          self.send_message_to_user(uid, self.get_message_for_state({}, 'search_result', language, uid))
        end
      rescue StandardError => e
        self.handle_search_error(uid, e)
      end
    end

    def handle_search_error(uid, e)
      self.send_message_to_user(uid, I18n.t(:smooch_v2_search_error))
      sm = CheckStateMachine.new(uid)
      sm.reset
      self.handle_exception(e)
    end

    def submit_search_query_for_verification(uid, app_id)
      self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
      self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
      self.send_message_to_user(uid, I18n.t(:smooch_v2_search_submit))
    end

    def ask_for_more_details(uid, message_id, app_id)
      list = self.list_of_bundled_messages_from_user(uid)
      unless list.empty?
        last = JSON.parse(list.last)
        if last['_id'] == message_id
          self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
          self.send_message_to_user(uid, I18n.t(:smooch_v2_add_more_details_menu))
        end
      end
    end

    def get_search_results(uid, last_message, team_id)
      results = []
      begin
        list = self.list_of_bundled_messages_from_user(uid)
        message = self.bundle_list_of_messages(list, last_message)
        type = message['type'] || 'text'
        if type == 'text'
          text = message['text'].gsub(/^[0-9]+$/, '')
          if text.split(/\s+/).reject{ |w| w.blank? }.size <= 3
            results = CheckSearch.new({ keyword: text, eslimit: 3, sort: 'demand', team_id: team_id }.to_json).medias
          else
            results = Bot::Alegre.get_similar_texts([team_id], message['text']).sort{ |a, b| a[1] <=> b[1] }.last(3).to_h.keys.reverse.collect{ |id| ProjectMedia.find(id) }
          end
        else
          threshold = Bot::Alegre.get_threshold_for_query(type, ProjectMedia.new(team_id: team_id))[:value]
          results = Bot::Alegre.get_items_with_similar_media(message['mediaUrl'], { value: threshold }, [team_id], "/#{type}/similarity/").sort{ |a, b| a[1] <=> b[1] }.last(3).to_h.keys.reverse.collect{ |id| ProjectMedia.find(id) }
        end
      rescue StandardError => e
        self.handle_search_error(uid, e)
      end
      results
    end

    def format_search_results(results)
      results.collect{ |r| "#{r.title}\n#{r.analysis_published_article_url}" }.join("\n\n")
    end
  end
end
