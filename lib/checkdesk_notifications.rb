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

        url = URI.parse(webhook)

        data = {
          payload: {
            channel: channel,
            text: message
          }.to_json
        }

        self.request_slack(url, data)
      end

      def request_slack(url, data)
        http = CheckdeskNotifications::Slack::Request.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new(url.request_uri)
        request.set_form_data(data)
        http.request(request)
        self.sent_to_slack = true
      end
    end
  end
end
