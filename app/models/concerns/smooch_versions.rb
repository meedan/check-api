require 'active_support/concern'

module SmoochVersions
  extend ActiveSupport::Concern

  module ClassMethods
    ::DynamicAnnotation::Field.class_eval do
      def smooch_user_slack_channel_url
        Concurrent::Future.execute(executor: POOL) do
          return unless self.field_name == 'smooch_data'
          slack_channel_url = ''
          data = self.value_json
          unless data.nil?
            key = "SmoochUserSlackChannelUrl:Team:#{self.team.id}:#{data['authorId']}"
            slack_channel_url = Rails.cache.read(key)
            if slack_channel_url.blank?
              # obj = self.associated
              obj = self.annotation.annotated
              slack_channel_url = get_slack_channel_url(obj, data)
              Rails.cache.write(key, slack_channel_url) unless slack_channel_url.blank?
            end
          end
          slack_channel_url
        end
      end

      def smooch_user_external_identifier
        Concurrent::Future.execute(executor: POOL) do
          return unless self.field_name == 'smooch_data'
          data = self.value_json
          Rails.cache.fetch("smooch:user:external_identifier:#{data['authorId']}") do
            field = DynamicAnnotation::Field.where('field_name = ? AND dynamic_annotation_fields_value(field_name, value) = ?', 'smooch_user_id', data['authorId'].to_json).last
            return '' if field.nil?
            user = JSON.parse(field.annotation.load.get_field_value('smooch_user_data')).with_indifferent_access[:raw][:clients][0]
            case user[:platform]
            when 'whatsapp'
              user[:displayName]
            when 'telegram'
              '@' + user[:raw][:username].to_s
            when 'messenger', 'viber', 'line'
              user[:externalId]
            when 'twitter'
              '@' + user[:raw][:screen_name]
            else
              ''
            end
          end
        end
      end

      def smooch_report_received_at
        Concurrent::Future.execute(executor: POOL) do
          begin
            self.annotation.load.get_field_value('smooch_report_received').to_i
          rescue
            nil
          end
        end
      end

      def smooch_report_update_received_at
        Concurrent::Future.execute(executor: POOL) do
          begin
            field = self.annotation.load.get_field('smooch_report_received')
            field.created_at != field.updated_at ? field.value.to_i : nil
          rescue
            nil
          end
        end
      end

      def smooch_user_request_language
        Concurrent::Future.execute(executor: POOL) do
          return '' unless self.field_name == 'smooch_data'
          self.value_json['language'].to_s
        end
      end

      private

      def get_slack_channel_url(obj, data)
        slack_channel_url = nil
        tid = obj.team_id
        smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', annotation_type: 'smooch_user')
        .where('dynamic_annotation_fields_value(field_name, value) = ?', data['authorId'].to_json)
        .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
        .where("a.annotated_type = ? AND a.annotated_id = ?", 'Team', tid).last
        unless smooch_user_data.nil?
          field_value = DynamicAnnotation::Field.where(field_name: 'smooch_user_slack_channel_url', annotation_type: 'smooch_user', annotation_id: smooch_user_data.annotation_id).last
          slack_channel_url = field_value.value unless field_value.nil?
        end
        slack_channel_url
      end
    end
  end
end
