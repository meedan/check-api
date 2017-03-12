module CheckNotifications
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
        http = CheckNotifications::Slack::Request.new(url.host, url.port)
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

      def to_slack(text)
        # https://api.slack.com/docs/message-formatting#how_to_escape_characters
        { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;' }.each { |k,v|
          text = text.gsub(k,v)
        }
        text
      end

      def to_slack_url(url, text)
        url.insert(0, "#{CONFIG['checkdesk_client']}/") unless url.start_with? "#{CONFIG['checkdesk_client']}/"
        text = self.to_slack(text)
        text = text.gsub("\n", ' ')
        "<#{url}|#{text}>"
      end

      def to_slack_quote(text)
        text = I18n.t(:blank) if text.blank?
        text = self.to_slack(text)
        text.insert(0, "\n") unless text.start_with? "\n"
        text.gsub("\n", "\n>")
      end
    end

    module InstanceMethods
      def sent_to_slack
        @sent_to_slack
      end

      def sent_to_slack=(bool)
        @sent_to_slack = bool
      end

      def parse_slack_options
        options = self.class.slack_options
        return if options.has_key?(:if) && !options[:if].call(self)

        webhook = options[:webhook].call(self)
        channel = options[:channel].call(self)
        message = options[:message].call(self)

        [webhook, channel, message]
      end

      def notify_slack
        webhook, channel, message = self.parse_slack_options

        return if webhook.blank? || channel.blank? || message.blank?

        data = {
          payload: {
            channel: channel,
            text: message.gsub('\\n', "\n")
          }.to_json
        }

        Rails.env === 'test' ? self.request_slack(webhook, data) : CheckNotifications::Slack::Worker.perform_async(webhook, data)
      end

      def request_slack(webhook, data)
        self.class.request(webhook, data)
        self.sent_to_slack = true
      end
    end

    class Worker
      include ::Sidekiq::Worker
      include CheckNotifications::Slack::ClassMethods

      def perform(webhook, data)
        request(webhook, data)
      end
    end
  end
end
