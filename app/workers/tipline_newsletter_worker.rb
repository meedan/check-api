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
              introduction = newsletter['smooch_newsletter_introduction'].to_s.gsub('{date}', date).gsub('{channel}', ts.platform)
              content = Bot::Smooch.build_newsletter_content(newsletter, language, team_id).gsub('{date}', date).gsub('{channel}', ts.platform)
              Bot::Smooch.get_installation { |i| i.id == tbi.id }
              response = Bot::Smooch.send_final_message_to_user(ts.uid, content, workflow, language)
              Bot::Smooch.save_smooch_response(response, nil, nil, 'newsletter', language, { introduction: introduction })
            end
          end
        end
      end
    end
  end
end
