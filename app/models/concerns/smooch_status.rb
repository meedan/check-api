require 'active_support/concern'

module SmoochStatus
  extend ActiveSupport::Concern

  module ClassMethods
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
      after_save do
        if self.field_name == 'smooch_user_slack_channel_url'
          smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_type: 'smooch_user', annotation_id: self.annotation.id).last
          value = smooch_user_data.value_json unless smooch_user_data.nil?
          a = self.annotation
          Rails.cache.write("SmoochUserSlackChannelUrl:Team:#{a.team_id}:#{value['id']}", self.value) unless value.blank?
        end
      end
    end
  end
end
