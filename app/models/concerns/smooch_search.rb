require 'active_support/concern'

module SmoochSearch
  extend ActiveSupport::Concern

  module ClassMethods
    # This method runs in background
    def search(app_id, uid, language)
      sm = CheckStateMachine.new(uid)
      begin
        self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
        sleep 60
        results = self.get_search_results
        if results.empty?
          self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
          self.send_message_to_user(uid, I18n.t(:smooch_v2_search_no_results))
        else
          self.send_message_to_user(uid, self.format_search_results(results))
          sm.go_to_search_result
          self.send_message_to_user(uid, self.get_message_for_state({}, 'search_result', language, uid))
        end
      rescue StandardError => e
        self.send_message_to_user(uid, I18n.t(:smooch_v2_search_error))
        sm.reset
        self.handle_exception(e)
      end
    end

    def submit_search_query_for_verification(uid, app_id)
      self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
      self.bundle_messages(uid, '', app_id, 'default_requests', nil, true)
      self.send_message_to_user(uid, I18n.t(:smooch_v2_search_submit))
    end

    def ask_for_more_details(uid, message_id, app_id)
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      list = redis.lrange(key, 0, redis.llen(key))
      unless list.empty?
        last = JSON.parse(list.last)
        if last['_id'] == message_id
          self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
          self.send_message_to_user(uid, I18n.t(:smooch_v2_add_more_details_menu))
        end
      end
    end

    # TODO: Implement this logic
    def get_search_results
      ProjectMedia.last(3)
      # []
    end

    # TODO: Implement this logic
    def format_search_results(results)
      'Search results go here'
    end
  end
end 
