class TiplineNewsletterWorker
  include Sidekiq::Worker

  def perform(team_id, language)
    tbi = TeamBotInstallation.where(user_id: BotUser.smooch_user&.id.to_i, team_id: team_id.to_i).last
    unless tbi.nil?
      tbi.settings['smooch_workflows'].to_a.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          newsletter = workflow['smooch_newsletter']
          Rails.logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] Preparing newsletter to be sent..."
          if !newsletter.nil? && Bot::Smooch.newsletter_content_changed?(newsletter, language, team_id)
            date = I18n.l(Time.now.to_date, locale: language.to_s.tr('_', '-'), format: :long)
            TiplineSubscription.where(language: language, team_id: team_id).each do |ts|
              Rails.logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] Sending newsletter to subscriber ##{ts.id}..."
              begin
                introduction = newsletter['smooch_newsletter_introduction'].to_s.gsub('{date}', date).gsub('{channel}', ts.platform)
                content = Bot::Smooch.build_newsletter_content(newsletter, language, team_id).gsub('{date}', date).gsub('{channel}', ts.platform)
                Bot::Smooch.get_installation { |i| i.id == tbi.id }
                response = Bot::Smooch.send_final_message_to_user(ts.uid, content, workflow, language)
                Bot::Smooch.save_smooch_response(response, nil, nil, 'newsletter', language, { introduction: introduction })
                Rails.logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] Newsletter sent to subscriber ##{ts.id}, response: #{response.inspect}"
              rescue StandardError => e
                Rails.logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] Could not send newsletter to subscriber ##{ts.id}: #{e.message}"
              end
            end
          else
            Rails.logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] Not sending newsletter because content hasn't changed since the last delivery"
          end
        end
      end
    end
  end
end
