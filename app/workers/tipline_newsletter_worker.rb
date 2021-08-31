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
              username = Bot::Smooch.user_name_from_uid(ts.uid)
              content = Bot::Smooch.build_newsletter_content(newsletter, language, team_id)
              fallback = I18n.t(:smooch_bot_message_newsletter_fallback, { locale: language, name: username, date: date, content: content })
              Bot::Smooch.get_installation { |i| i.id == tbi.id }
              message = Bot::Smooch.format_template_message(Bot::Smooch::NEWSLETTER_TEMPLATE_NAME, [date, content], nil, fallback, language, username)
              Bot::Smooch.send_message_to_user(ts.uid, message)
            end
          end
        end
      end
    end
  end
end
