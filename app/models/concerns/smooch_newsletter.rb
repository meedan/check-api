require 'active_support/concern'

module SmoochNewsletter
  extend ActiveSupport::Concern

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
                next_date: I18n.l(CronParser.new(Bot::Smooch.newsletter_cron(newsletter)).next(Time.now).to_date, locale: language.to_s.tr('_', '-'), format: :short),
                next_time: "#{newsletter['smooch_newsletter_time']}:00 #{newsletter['smooch_newsletter_timezone']}",
                paused: !Bot::Smooch.newsletter_content_changed?(newsletter, language, self.team_id)
              }
            end
          end
        end
        information
      end

      def get_newsletter_template_name
        self.settings['smooch_template_name_for_newsletter'] || 'newsletter'
      end
    end

    def toggle_subscription(uid, language, team_id, platform)
      s = TiplineSubscription.where(uid: uid, language: language, team_id: team_id).last
      sm = CheckStateMachine.new(uid)
      if s.nil?
        TiplineSubscription.create!(uid: uid, language: language, team_id: team_id, platform: platform)
        self.send_message_to_user(uid, I18n.t(:smooch_bot_message_subscribed, locale: language))
      else
        s.destroy!
        self.send_message_to_user(uid, I18n.t(:smooch_bot_message_unsubscribed, locale: language))
      end
      sm.reset
      self.clear_user_bundled_messages(uid)
    end

    def newsletter_is_set?(workflow)
      workflow['smooch_newsletter'] && workflow['smooch_newsletter']['smooch_newsletter_time'] && workflow['smooch_newsletter']['smooch_newsletter_timezone'] && workflow['smooch_newsletter']['smooch_newsletter_day']
    end

    def build_newsletter_content(newsletter, language, team_id, cache = true)
      content = nil
      content = newsletter['smooch_newsletter_body'] unless newsletter['smooch_newsletter_body'].blank?
      content = Bot::Smooch.render_articles_from_rss_feed(newsletter['smooch_newsletter_feed_url'], newsletter['smooch_newsletter_number_of_articles']) unless newsletter['smooch_newsletter_feed_url'].blank?
      content = content.blank? ? [] : content.to_s.split("\n\n")
      content = content.size > 1 ? content.map(&:chomp).collect{ |entry| " • #{entry}" }.join('') : content.first
      Rails.cache.write("newsletter:content_hash:team:#{team_id}:#{language}", Digest::MD5.hexdigest(content)) if cache
      content
    end

    def newsletter_content_changed?(newsletter, language, team_id)
      Rails.cache.read("newsletter:content_hash:team:#{team_id}:#{language}").to_s != Digest::MD5.hexdigest(Bot::Smooch.build_newsletter_content(newsletter, language, team_id, false).to_s)
    end

    def newsletter_cron(newsletter)
      hour = newsletter['smooch_newsletter_time'].to_i
      timezone = newsletter['smooch_newsletter_timezone'].to_s.upcase
      # Mapping for timezones not supported by Ruby's DateTime
      timezone = {
        'PHT' => '+0800',
        'CAT' => '+0200'
      }[timezone] || timezone
      time_set = DateTime.parse("#{hour}:00 #{timezone}")
      time_utc = time_set.utc
      days = (0..6).to_a
      day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'].index(newsletter['smooch_newsletter_day'])
      day += (time_utc.strftime('%w').to_i - time_set.strftime('%w').to_i)
      "#{time_utc.min} #{time_utc.hour} * * #{days[day]}"
    end
  end
end
