module CheckdeskNotifications
  module Slack
    def self.included(base)
      base.send :extend, ClassMethods
    end

    class Request < ::Net::HTTP
    end
  
    module ClassMethods
      def slack_options
        @slack_options
      end

      def slack_options=(options)
        @slack_options = options
      end

      def request(webhook, data)
        url = URI.parse(webhook)
        http = CheckdeskNotifications::Slack::Request.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(url.request_uri)
        request.set_form_data(data)
        http.request(request)
      end

      def notifies_slack(options = {})
        send("after_#{options[:on]}", :notify_slack)

        self.slack_options = options
        
        send :include, InstanceMethods
      end
    end

    module InstanceMethods
      def sent_to_slack
        @sent_to_slack
      end

      def sent_to_slack=(bool)
        @sent_to_slack = bool
      end

      def notify_slack
        options = self.class.slack_options
        return if options.has_key?(:if) && !options[:if].call(self)

        webhook = options[:webhook].call(self)
        channel = options[:channel].call(self)
        message = options[:message].call(self)

        return if webhook.blank? || channel.blank? || message.blank?

        data = {
          payload: {
            channel: channel,
            text: message
          }.to_json
        }

        Rails.env === 'test' ? self.request_slack(webhook, data) : CheckdeskNotifications::Slack::Worker.perform_async(webhook, data)
      end

      def request_slack(webhook, data)
        self.class.request(webhook, data)
        self.sent_to_slack = true
      end
    end

    class Worker
      include ::Sidekiq::Worker
      include CheckdeskNotifications::Slack::ClassMethods

      def perform(webhook, data)
        request(webhook, data)
      end
    end
  end
end
