module CheckNotifications
  module Pusher
    def self.included(base)
      base.send :extend, ClassMethods
    end

    def pusher_channel
      'check-channel-' + Digest::MD5.hexdigest(self.class_name + ':' + self.id.to_s + ':pusher_channel')
    end

    module ClassMethods
      def pusher_options
        @pusher_options
      end

      def send_to_pusher(channels, event, data, actor_session_id)
        ::Pusher.trigger(channels, event, { message: data, actor_session_id: actor_session_id }) unless CONFIG['pusher_key'].blank?
      end

      def pusher_options=(options)
        @pusher_options = options
      end

      def notifies_pusher(options = {})
        events = [options[:on]].flatten

        pusher_options = self.pusher_options || {}

        events.each do |event|
          send("after_#{event}", ->(_obj) { notify_pusher(event) })
          pusher_options[event] = options
        end

        self.pusher_options = pusher_options

        send :include, InstanceMethods
      end
    end

    module InstanceMethods
      def sent_to_pusher
        @sent_to_pusher
      end

      def sent_to_pusher=(bool)
        @sent_to_pusher = bool
      end

      def parse_pusher_options(action)
        options = self.class.pusher_options[action]
        return if options.has_key?(:if) && !options[:if].call(self)

        event = options[:event].is_a?(String) ? options[:event] : options[:event].call(self)
        targets = options[:targets].call(self)
        data = options[:data].call(self)

        [event, targets, data]
      end

      def bulk_channels(action)
        action = :save if action == :update
        options = self.class.pusher_options[action]
        options[:bulk_targets] ? options[:bulk_targets].call(self).reject{ |t| t.blank? }.map(&:pusher_channel) : []
      end

      def actor_session_id
        RequestStore[:request].blank? ? '' : RequestStore[:request].headers['X-Check-Client'].to_s
      end

      def parse_data(data)
        whitelist = [:annotation_type, :annotated_id, :id, :source_id, :lock_version, :class_name, :user_id, :annotator_id, :target_id]
        JSON.parse(data).reject{ |k, _v| !whitelist.include?(k.to_sym) }
      end

      def notify_pusher(action)
        event, targets, data = self.parse_pusher_options(action)

        return if event.blank? || targets.blank? || data.blank?

        channels = targets.reject{ |t| t.blank? }.map(&:pusher_channel)
        data = '{}' if data == 'null'

        self.request_pusher(channels, event, self.parse_data(data).to_json, self.actor_session_id) if Rails.env == 'test'
        CheckNotifications::Pusher::Worker.perform_in(1.second, ['check-api-global-channel'], 'update', self.parse_data(data).merge({ pusherChannels: channels, pusherEvent: event }).to_json, self.actor_session_id)
      end

      def request_pusher(channels, event, data, actor_session_id)
        self.class.send_to_pusher(channels, event, data, actor_session_id)
        self.sent_to_pusher = true
      end
    end

    class Worker
      include ::Sidekiq::Worker
      include CheckNotifications::Pusher::ClassMethods

      sidekiq_options queue: 'pusher', retry: 0

      def perform(channels, event, data, actor_session_id)
        send_to_pusher(channels, event, data, actor_session_id)
      end
    end
  end
end
