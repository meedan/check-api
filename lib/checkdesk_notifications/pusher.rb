module CheckdeskNotifications
  module Pusher
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def pusher_options
        @pusher_options
      end

      def send_to_pusher(channel, event, data)
        ::Pusher.trigger(channel, event, { message: data })
      end

      def pusher_options=(options)
        @pusher_options = options
      end

      def notifies_pusher(options = {})
        send("after_#{options[:on]}", :notify_pusher)

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
        target = options[:target].call(self)
        data = options[:data].call(self)

        [event, target, data]
      end

      def notify_pusher
        event, target, data = self.parse_pusher_options
        channel = target.pusher_channel

        return if event.blank? || target.blank? || data.blank?

        Rails.env === 'test' ? self.request_pusher(channel, event, data) : CheckdeskNotifications::Pusher::Worker.perform_async(channel, event, data)
      end

      def pusher_channel
        Digest::MD5.hexdigest(self.class.name + ':' + self.id.to_s + ':pusher_channel')
      end

      def request_pusher(channel, event, data)
        self.class.send_to_pusher(channel, event, data)
        self.sent_to_pusher = true
      end
    end

    class Worker
      include ::Sidekiq::Worker
      include CheckdeskNotifications::Pusher::ClassMethods

      def perform(channel, event, data)
        send_to_pusher(channel, event, data)
      end
    end
  end
end
