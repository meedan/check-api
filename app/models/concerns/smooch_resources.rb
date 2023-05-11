require 'active_support/concern'

module SmoochResources
  extend ActiveSupport::Concern

  module ClassMethods
    TeamBotInstallation.class_eval do
      # Save resources (should we delete too? for now no, because requests can reference them)
      # FIXME: Check API clients should handle it directly
      after_save do
        if self.bot_user.identifier == 'smooch'
          Bot::Smooch.save_resources(self.team_id, self.settings)
        end
      end
    end

    def send_rss_to_user(uid, resource, workflow, language, no_cache = false)
      team = Team.find(self.config['team_id'].to_i)
      message = []
      unless resource.blank?
        message << "*#{resource['smooch_custom_resource_title']}*" unless resource['smooch_custom_resource_title'].to_s.strip.blank?
        message << resource['smooch_custom_resource_body'] unless resource['smooch_custom_resource_body'].to_s.strip.blank?
        unless resource['smooch_custom_resource_feed_url'].blank?
          message << Rails.cache.fetch("smooch:rss_feed:#{Digest::MD5.hexdigest(resource['smooch_custom_resource_feed_url'])}:#{resource['smooch_custom_resource_number_of_articles']}", force: no_cache, expires_in: 15.minutes) do
            self.render_articles_from_rss_feed(resource['smooch_custom_resource_feed_url'], resource['smooch_custom_resource_number_of_articles'])
          end
        end
      end
      message = message.join("\n\n")
      message = UrlRewriter.shorten_and_utmize_urls(message, team.get_outgoing_urls_utm_code || 'check_resource') if team.get_shorten_outgoing_urls
      self.send_final_messages_to_user(uid, message, workflow, language) unless message.blank?
    end

    def send_resource_to_user(uid, workflow, option, language)
      resource = workflow['smooch_custom_resources'].to_a.find{ |r| r['smooch_custom_resource_id'] == option['smooch_menu_custom_resource_id'] }
      self.send_rss_to_user(uid, resource, workflow, language)
      resource.blank? ? nil : BotResource.find_by_uuid(resource['smooch_custom_resource_id'])
    end

    def send_message_to_user_on_timeout(uid, language)
      sm = CheckStateMachine.new(uid)
      redis = Redis.new(REDIS_CONFIG)
      user_messages_count = redis.llen("smooch:bundle:#{uid}")
      message = self.get_custom_string(:timeout, language)
      self.send_message_to_user(uid, message) if user_messages_count > 0 && sm.state.value != 'main'
      sm.reset
    end

    def render_articles_from_rss_feed(url, count = 3)
      rss_feed = RssFeed.new(url)
      content = rss_feed.get_articles(count).join("\n\n")
      team = Team.current
      team&.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(content, team.get_outgoing_urls_utm_code || 'rss_preview') : content
    end

    def refresh_rss_feeds_cache
      begin
        bot = BotUser.smooch_user
        TeamBotInstallation.where(user_id: bot.id).each do |tbi|
          tbi.settings['smooch_workflows'].to_a.collect{ |w| w['smooch_custom_resources'].to_a + w['smooch_message_smooch_bot_no_action'].to_a }.flatten.reject{ |r| r.blank? }.each do |resource|
            has_feed_url = begin !resource['smooch_custom_resource_feed_url'].blank? rescue false end
            next unless has_feed_url
            content = self.render_articles_from_rss_feed(resource['smooch_custom_resource_feed_url'], resource['smooch_custom_resource_number_of_articles'])
            Rails.cache.write("smooch:rss_feed:#{Digest::MD5.hexdigest(resource['smooch_custom_resource_feed_url'])}:#{resource['smooch_custom_resource_number_of_articles']}", content, expires_in: 1.hour) unless content.blank?
          end
        end
      rescue
        nil
      end
      self.delay_for(15.minutes, { queue: 'smooch', retry: 0 }).refresh_rss_feeds_cache unless Rails.env.test? # Avoid infinite loop
    end

    def save_resources(team_id, settings)
      settings['smooch_workflows'].to_a.collect{ |w| w['smooch_custom_resources'].to_a }.flatten.reject{ |r| r.blank? }.each do |resource|
        br = BotResource.where(team_id: team_id, uuid: resource['smooch_custom_resource_id']).last || BotResource.new
        br.uuid = resource['smooch_custom_resource_id']
        br.title = resource['smooch_custom_resource_title']
        br.content = resource['smooch_custom_resource_body']
        br.feed_url = resource['smooch_custom_resource_feed_url']
        br.number_of_articles = resource['smooch_custom_resource_number_of_articles'].to_i
        br.team_id = team_id
        br.skip_check_ability = true
        br.save!
      end
    end
  end
end
