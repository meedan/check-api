class TiplineNewsletterWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch_priority', retry: 0

  def perform(team_id, language)
    tbi = TeamBotInstallation.where(user_id: BotUser.smooch_user&.id.to_i, team_id: team_id.to_i).last
    newsletter = Bot::Smooch.get_newsletter(team_id, language)
    log(team_id, language, 'Not sending newsletter because it does not exist or is not enabled') unless newsletter&.enabled
    count = 0
    unless tbi.nil?
      tbi.settings['smooch_workflows'].to_a.each do |workflow|
        if workflow['smooch_workflow_language'] == language
          log team_id, language, 'Preparing newsletter to be sent...'
          if !newsletter.nil? && newsletter.content_has_changed?
            date = I18n.l(Time.now.to_date, locale: language.to_s.tr('_', '-'), format: :long)
            content = newsletter.build_content.gsub('{date}', date)
            TiplineSubscription.where(language: language, team_id: team_id).find_each do |ts|
              log team_id, language, "Sending newsletter to subscriber ##{ts.id}..."
              begin
                RequestStore.store[:smooch_bot_platform] = ts.platform
                introduction = newsletter.introduction.to_s.gsub('{date}', date).gsub('{channel}', ts.platform)
                content = content.gsub('{channel}', ts.platform)
                Bot::Smooch.get_installation { |i| i.id == tbi.id }
                response = Bot::Smooch.send_final_messages_to_user(ts.uid, content, workflow, language, 5)
                Bot::Smooch.save_smooch_response(response, nil, nil, 'newsletter', language, { introduction: introduction })
                log team_id, language, "Newsletter sent to subscriber ##{ts.id}, response: #{response.inspect}"
                count += 1
              rescue StandardError => e
                log team_id, language, "Could not send newsletter to subscriber ##{ts.id}: #{e.message}"
              end
            end
            User.current = BotUser.smooch_user
            newsletter.skip_check_ability = true
            newsletter.last_sent_at = Time.now
            newsletter.save!
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
    logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] #{message}"
  end
end
