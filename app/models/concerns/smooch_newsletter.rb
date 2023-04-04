require 'active_support/concern'

module SmoochNewsletter
  extend ActiveSupport::Concern

  module ClassMethods
    TeamBotInstallation.class_eval do
      def smooch_newsletter_information
        information = {} # Per language
        if self.bot_user.identifier == 'smooch'
          self.settings['smooch_workflows'].to_a.each do |workflow|
            language = workflow['smooch_workflow_language']
            newsletter = Bot::Smooch.get_newsletter(self.team_id, language)
            unless newsletter.nil?
              next_date_and_time_utc = CronParser.new(newsletter.cron_notation).next(Time.now).to_datetime
              next_date_and_time = begin next_date_and_time_utc.in_time_zone(newsletter.timezone.gsub(/ .*$/, '')) rescue next_date_and_time_utc end
              information[language] = {
                subscribers_count: TiplineSubscription.where(team_id: self.team_id, language: language).count,
                next_date_and_time: I18n.l(next_date_and_time, locale: language.to_s.tr('_', '-'), format: :long) + " - #{newsletter.timezone}",
                paused: newsletter.content_has_changed?
              }
            end
          end
        end
        information
      end
    end

    def user_is_subscribed_to_newsletter?(uid, language, team_id)
      TiplineSubscription.where(uid: uid, language: language, team_id: team_id).exists?
    end

    def toggle_subscription(uid, language, team_id, platform, workflow)
      s = TiplineSubscription.where(uid: uid, language: language, team_id: team_id).last
      CheckStateMachine.new(uid).reset
      if s.nil?
        TiplineSubscription.create!(uid: uid, language: language, team_id: team_id, platform: platform)
        self.send_final_message_to_user(uid, self.subscription_message(uid, language, true, false), workflow, language)
      else
        s.destroy!
        self.send_final_message_to_user(uid, self.subscription_message(uid, language, false, false), workflow, language)
      end
      self.clear_user_bundled_messages(uid)
    end

    def get_newsletter(team_id, language)
      TiplineNewsletter.where(team_id: team_id, language: language).last
    end

    def send_newsletter_on_template_button_click(message, uid, language, info)
      newsletter_language = info[1] || language
      newsletter_workflow = self.get_workflow(newsletter_language)
      date = I18n.l(Time.now.to_date, locale: newsletter_language.to_s.tr('_', '-'), format: :long)
      newsletter = self.get_newsletter(self.config['team_id'], newsletter_language)
      content = newsletter.build_content(false).gsub('{date}', date).gsub('{channel}', self.get_platform_from_message(message))
      Bot::Smooch.send_final_messages_to_user(uid, content, newsletter_workflow, newsletter_language)
    end
  end
end
