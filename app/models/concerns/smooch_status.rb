require 'active_support/concern'

module SmoochStatus
  extend ActiveSupport::Concern

  module ClassMethods
    ::Workflow::VerificationStatus.class_eval do
      check_workflow from: :any, to: :any, actions: [:send_message]
    end

    Team.class_eval do
      def get_status_message_for_language(status, language)
        settings = self.settings || {}
        statuses = settings.with_indifferent_access[:media_verification_statuses] || {}
        message = nil
        statuses[:statuses].to_a.each do |s|
          if s[:id] == status
            message = s.dig(:locales, language, :message) if s[:should_send_message]
          end
        end
        message
      end
    end

    ::DynamicAnnotation::Field.class_eval do
      include CheckPusher

      protected

      def send_message
        pm = self.annotation.annotated
        return unless Bot::Smooch.team_has_smooch_bot_installed(pm)
        ::Bot::Smooch.delay_for(1.second, { queue: 'smooch_priority', retry: 0 }).send_message_on_status_change(pm.id, self.value, self.class.actor_session_id)
      end
    end
  end
end
