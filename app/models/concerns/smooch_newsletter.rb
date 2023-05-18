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
  end
end
