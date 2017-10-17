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

      def send_to_pusher(channels, event, data)
        ::Pusher.trigger(channels, event, { message: data }) unless CONFIG['pusher_key'].blank?
      end

      def pusher_options=(options)
        @pusher_options = options
      end

      def notifies_pusher(options = {})
        events = [options[:on]].flatten
        events.each do |event|
          send("after_#{event}", :notify_pusher)
        end

        self.pusher_options = options

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

      def parse_pusher_options
        options = self.class.pusher_options
        return if options.has_key?(:if) && !options[:if].call(self)

        event = options[:event]
        targets = options[:targets].call(self)
        data = options[:data].call(self)

        [event, targets, data]
      end

      def notify_pusher
        event, targets, data = self.parse_pusher_options

        return if event.blank? || targets.blank? || data.blank?

        channels = targets.reject{ |t| t.blank? }.map(&:pusher_channel)

        return if channels.blank?

        Rails.env === 'test' ? self.request_pusher(channels, event, data) : CheckNotifications::Pusher::Worker.perform_in(1.second, channels, event, data)
      end

      def request_pusher(channels, event, data)
        self.class.send_to_pusher(channels, event, data)
        self.sent_to_pusher = true
      end
    end

    class Worker
      include ::Sidekiq::Worker
      include CheckNotifications::Pusher::ClassMethods

      def perform(channels, event, data)
        send_to_pusher(channels, event, data)
      end
    end
  end
end
