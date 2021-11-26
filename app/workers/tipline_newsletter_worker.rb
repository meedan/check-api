class TiplineNewsletterWorker
  include Sidekiq::Worker

  def perform(team_id, language)
    tbi = TeamBotInstallation.where(user_id: BotUser.smooch_user&.id.to_i, team_id: team_id.to_i).last
    unless tbi.nil?
      tbi.settings['smooch_workflows'].to_a.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          newsletter = workflow['smooch_newsletter']
          if !newsletter.nil? && Bot::Smooch.newsletter_content_changed?(newsletter, language, team_id)
            date = I18n.l(Time.now.to_date, locale: language.to_s.tr('_', '-'), format: :short)
            TiplineSubscription.where(language: language, team_id: team_id).each do |ts|
              content = Bot::Smooch.build_newsletter_content(newsletter, language, team_id)
              fallback = I18n.t(:smooch_bot_message_newsletter_fallback, { platform: ts.platform, locale: language, team: tbi.team.name, date: date, content: content, unsubscribe: I18n.t(:unsubscribe, { locale: language }) })
              Bot::Smooch.get_installation { |i| i.id == tbi.id }
              message = Bot::Smooch.format_template_message(tbi.get_newsletter_template_name, [ts.platform, tbi.team.name, date, content], nil, fallback, language)
              Bot::Smooch.send_message_to_user(ts.uid, message)
            end
          end
        end
      end
    end
  end
end
