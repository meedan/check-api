require 'active_support/concern'

module SmoochNewsletter
  extend ActiveSupport::Concern

  NEWSLETTER_TEMPLATE_NAME = 'newsletter_1'

  module ClassMethods
    TeamBotInstallation.class_eval do
      # Re-create the Sidekiq job
      after_save do
        if self.bot_user.identifier == 'smooch'
          self.settings['smooch_workflows'].to_a.each do |workflow|
            if Bot::Smooch.newsletter_is_set?(workflow)
              newsletter = workflow['smooch_newsletter']
              name = "newsletter:job:team:#{self.team_id}:#{workflow['smooch_workflow_language']}"
              Sidekiq::Cron::Job.destroy(name)
              Sidekiq::Cron::Job.create(name: name, cron: Bot::Smooch.newsletter_cron(newsletter), class: 'TiplineNewsletterWorker', args: [self.team_id, workflow['smooch_workflow_language']])
            end
          end
        end
      end

      def smooch_newsletter_information
        information = {} # Per language
        if self.bot_user.identifier == 'smooch'
          self.settings['smooch_workflows'].to_a.each do |workflow|
            if Bot::Smooch.newsletter_is_set?(workflow)
              newsletter = workflow['smooch_newsletter']
              language = workflow['smooch_workflow_language']
              information[language] = {
                subscribers_count: TiplineSubscription.where(team_id: self.team_id, language: language).count,
                next_date: I18n.l(CronParser.new(Bot::Smooch.newsletter_cron(newsletter)).next(Time.now + 7.days).to_date, locale: language.to_s.tr('_', '-'), format: :short),
                next_time: "#{newsletter['smooch_newsletter_time']}:00 #{newsletter['smooch_newsletter_timezone']}",
                paused: !Bot::Smooch.newsletter_content_changed?(newsletter, language, self.team_id)
              }
            end
          end
        end
        information
      end
    end

    def toggle_subscription(uid, language, team_id)
      s = TiplineSubscription.where(uid: uid, language: language, team_id: team_id).last
      sm = CheckStateMachine.new(uid)
      if s.nil?
        TiplineSubscription.create!(uid: uid, language: language, team_id: team_id)
        self.send_message_to_user(uid, I18n.t(:smooch_bot_message_subscribed))
      else
        s.destroy!
        self.send_message_to_user(uid, I18n.t(:smooch_bot_message_unsubscribed))
      end
      sm.reset
    end

    def user_name_from_uid(uid)
      user_data = begin DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: uid).last.annotation.load.get_field_value('smooch_user_data') rescue nil end
      user_data.nil? ? nil : JSON.parse(user_data).dig('raw', 'clients', 0, 'raw','profile', 'name')
    end

    def newsletter_is_set?(workflow)
      workflow['smooch_newsletter'] && workflow['smooch_newsletter']['smooch_newsletter_time'] && workflow['smooch_newsletter']['smooch_newsletter_timezone'] && workflow['smooch_newsletter']['smooch_newsletter_day']
    end

    def build_newsletter_content(newsletter, language, team_id, cache = true)
      content = []
      content << newsletter['smooch_newsletter_body'] unless newsletter['smooch_newsletter_body'].blank?
      content << Bot::Smooch.render_articles_from_rss_feed(newsletter['smooch_newsletter_feed_url'], newsletter['smooch_newsletter_number_of_articles']) unless newsletter['smooch_newsletter_feed_url'].blank?
      content = content.empty? ? '' : content.join("\n\n")
      Rails.cache.write("newsletter:content_hash:team:#{team_id}:#{language}", Digest::MD5.hexdigest(content)) if cache
      content
    end

    def newsletter_content_changed?(newsletter, language, team_id)
      Rails.cache.read("newsletter:content_hash:team:#{team_id}:#{language}") != Digest::MD5.hexdigest(Bot::Smooch.build_newsletter_content(newsletter, language, team_id, false))
    end

    def newsletter_cron(newsletter)
      hour = DateTime.parse("#{newsletter['smooch_newsletter_time']}:00 #{newsletter['smooch_newsletter_timezone']}").utc.hour
      day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'].index(newsletter['smooch_newsletter_day'])
      "0 #{hour} * * #{day}"
    end
  end
end
