require 'active_support/concern'

module SmoochNewsletter
  extend ActiveSupport::Concern

  module ClassMethods
    def user_is_subscribed_to_newsletter?(uid, language, team_id)
      TiplineSubscription.where(uid: uid, language: language, team_id: team_id).exists?
    end

    def toggle_subscription(uid, language, team_id, platform, workflow)
      s = TiplineSubscription.where(uid: uid, language: language, team_id: team_id).last
      CheckStateMachine.new(uid).reset
      if s.nil?
        TiplineSubscription.create!(uid: uid, language: language, team_id: team_id, platform: platform)
        self.send_final_message_to_user(uid, self.subscription_message(uid, language, true, false), workflow, language)
      else
        s.destroy!
        self.send_final_message_to_user(uid, self.subscription_message(uid, language, false, false), workflow, language)
      end
      self.clear_user_bundled_messages(uid)
    end

    def get_newsletter(team_id, language)
      TiplineNewsletter.where(team_id: team_id, language: language).last
    end

    def unsubscribe_user_on_optout(json)
      # unsubscribing user from all newsletters if the error code is 131050 and the platform is WhatsApp
      if json.dig('destination', 'type') == 'whatsapp' && json.dig('error', 'underlyingError', 'errors', 0, 'code') == 131050
        uid = json['appUser']['_id']
        language = self.get_user_language(uid)
        self.unsubscribe_from_all_language(uid, language, self.config['team_id'].to_i, self.get_workflow(language))
      end
    end

    def unsubscribe_from_all_language(uid, language, team_id, workflow)
      TiplineSubscription.where(uid: uid, team_id: team_id).destroy_all
      # Call these methods to sync with `toggle_subscription` method
      self.send_final_message_to_user(uid, self.subscription_message(uid, language, false, false), workflow, language)
      self.clear_user_bundled_messages(uid)
    end
  end
end
