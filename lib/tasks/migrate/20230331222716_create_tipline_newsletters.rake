namespace :check do
  namespace :migrate do
    task create_tipline_newsletters: :environment do
      TeamBotInstallation.where(user: BotUser.smooch_user).find_each do |tbi|
        team = tbi.team
        tbi.get_smooch_workflows.to_a.each do |workflow|
          language = workflow['smooch_workflow_language']
          unless workflow['smooch_newsletter'].blank?
            if TiplineNewsletter.where(team_id: team.id, language: language).exists?
              puts "[#{Time.now}] Skipped tipline newsletter for #{team.name}, language #{language}, because it already exists"
            else
              newsletter = TiplineNewsletter.new
              newsletter.introduction = workflow.dig('smooch_newsletter', 'smooch_newsletter_introduction')
              newsletter.rss_feed_url = workflow.dig('smooch_newsletter', 'smooch_newsletter_feed_url')
              articles = workflow.dig('smooch_newsletter', 'smooch_newsletter_body').to_s.split("\n\n")
              newsletter.first_article = articles[0]
              newsletter.second_article = articles[1]
              newsletter.third_article = articles[2]
              newsletter.number_of_articles = [[workflow.dig('smooch_newsletter', 'smooch_newsletter_number_of_articles').to_i, articles.size].max, 3].min
              newsletter.send_every = workflow.dig('smooch_newsletter', 'smooch_newsletter_day')
              newsletter.timezone = workflow.dig('smooch_newsletter', 'smooch_newsletter_timezone')
              newsletter.time = Time.parse("#{workflow.dig('smooch_newsletter', 'smooch_newsletter_time')}:00")
              newsletter.last_sent_at = workflow.dig('smooch_newsletter', 'smooch_newsletter_last_sent_at')
              newsletter.language = language
              newsletter.team = team
              newsletter.save!
              puts "[#{Time.now}] Created tipline newsletter ##{newsletter.id} for #{team.name}, language #{language}"
            end
          end
        end
      end
    end
  end
end
