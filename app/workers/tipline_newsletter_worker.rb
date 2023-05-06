class TiplineNewsletterWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch_priority', retry: 0

  def perform(team_id, language, job_created_at = 0)
    tbi = TeamBotInstallation.where(user_id: BotUser.smooch_user&.id.to_i, team_id: team_id.to_i).last
    newsletter = Bot::Smooch.get_newsletter(team_id, language)
    count = 0
    return count if tbi.nil? || newsletter.nil? || !newsletter.enabled

    # For RSS newsletter, if content hasn't changed, don't send the newsletter (actually, pause it)
    if newsletter.content_type == 'rss' && !newsletter.content_has_changed?
      newsletter.enabled = false
      newsletter.save!
      log team_id, language, "RSS newsletter not sent because the content hasn't changed"
      return count
    end

    # For static newsletter, ignore if there is a newer scheduled newsletter
    if newsletter.content_type == 'static' && newsletter.updated_at.to_i > job_created_at
      log team_id, language, "Static newsletter not sent because it was rescheduled"
      return count
    end

    # Send newsletter
    log team_id, language, 'Preparing newsletter to be sent...'
    date = I18n.l(Time.now.to_date, locale: language.to_s.tr('_', '-'), format: :long)
    content = newsletter.build_content
    start = Time.now
    TiplineSubscription.where(language: language, team_id: team_id).find_each do |ts|
      log team_id, language, "Sending newsletter to subscriber ##{ts.id}..."
      begin
        RequestStore.store[:smooch_bot_platform] = ts.platform
        Bot::Smooch.get_installation { |i| i.id == tbi.id }

        response = Bot::Smooch.send_message_to_user(ts.uid, Bot::Smooch.format_template_message(newsletter.whatsapp_template_name, [date, newsletter.articles].flatten, nil, content, language))

        log team_id, language, "Newsletter sent to subscriber ##{ts.id}, response: #{response.inspect}"
        count += 1
      rescue StandardError => e
        log team_id, language, "Could not send newsletter to subscriber ##{ts.id}: #{e.message}"
      end
    end
    finish = Time.now

    # Save a delivery event for this newsletter
    TiplineNewsletterDelivery.create!({
      recipients_count: count,
      content: content,
      started_sending_at: start,
      finished_sending_at: finish,
      tipline_newsletter: newsletter
    })

    # Save the last time this newsletter was sent
    newsletter.update_column(:last_sent_at, Time.now)

    log team_id, language, "Newsletter sent to #{count} subscribers"

    # Static newsletter is paused after sent
    newsletter.update_column(:enabled, false) if newsletter.content_type == 'static'

    count
  end

  private

  def log(team_id, language, message)
    logger.info "[Smooch Bot] [Newsletter] [Team ##{team_id}] [Language #{language}] [#{Time.now}] #{message}"
  end
end
