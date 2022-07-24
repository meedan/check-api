class TiplineNewsletterWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch_priority', retry: 0

  def perform(team_id, language)
    tbi = TeamBotInstallation.where(user_id: BotUser.smooch_user&.id.to_i, team_id: team_id.to_i).last
    count = 0
    unless tbi.nil?
      tbi.settings['smooch_workflows'].to_a.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          newsletter = workflow['smooch_newsletter']
          log team_id, language, 'Preparing newsletter to be sent...'
          if !newsletter.nil? && Bot::Smooch.newsletter_content_changed?(newsletter, language, team_id)
            date = I18n.l(Time.now.to_date, locale: language.to_s.tr('_', '-'), format: :long)
            TiplineSubscription.where(language: language, team_id: team_id).each do |ts|
              log team_id, language, "Sending newsletter to subscriber ##{ts.id}..."
              begin
                RequestStore.store[:smooch_bot_platform] = ts.platform
                introduction = newsletter['smooch_newsletter_introduction'].to_s.gsub('{date}', date).gsub('{channel}', ts.platform)
                content = Bot::Smooch.build_newsletter_content(newsletter, language, team_id).gsub('{date}', date).gsub('{channel}', ts.platform)
                Bot::Smooch.get_installation { |i| i.id == tbi.id }
                response = Bot::Smooch.send_final_message_to_user(ts.uid, content, workflow, language)
                Bot::Smooch.save_smooch_response(response, nil, nil, 'newsletter', language, { introduction: introduction })
                log team_id, language, "Newsletter sent to subscriber ##{ts.id}, response: #{response.inspect}"
                count += 1
              rescue StandardError => e
                log team_id, language, "Could not send newsletter to subscriber ##{ts.id}: #{e.message}"
              end
            end
            User.current = BotUser.smooch_user
            tbi.skip_check_ability = true
            newsletter['smooch_newsletter_last_sent_at'] = Time.now
            tbi.save!
            User.current = nil
          else
            log team_id, language, 'Not sending newsletter because content has not changed since the last delivery'
          end
        end
      end
    end
    log team_id, language, "Newsletter sent to #{count} subscribers"
    count
  end

  private

  def log(team_id, language, message)
    Rails.logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] #{message}"
  end
end
