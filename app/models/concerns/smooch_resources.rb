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

    def send_resource_to_user(uid, workflow, option)
      message = []
      resource = workflow['smooch_custom_resources'].to_a.find{ |r| r['smooch_custom_resource_id'] == option['smooch_menu_custom_resource_id'] }
      unless resource.blank?
        message << "*#{resource['smooch_custom_resource_title']}*"
        message << resource['smooch_custom_resource_body'] unless resource['smooch_custom_resource_body'].to_s.strip.blank?
        unless resource['smooch_custom_resource_feed_url'].blank?
          message << Rails.cache.fetch("smooch:rss_feed:#{Digest::MD5.hexdigest(resource['smooch_custom_resource_feed_url'])}:#{resource['smooch_custom_resource_number_of_articles']}") do
            self.render_articles_from_rss_feed(resource['smooch_custom_resource_feed_url'], resource['smooch_custom_resource_number_of_articles'])
          end
        end
      end
      message = self.utmize_urls(message.join("\n\n"), 'resource')
      self.send_message_to_user(uid, message) unless message.blank?
      resource.blank? ? nil : BotResource.find_by_uuid(resource['smooch_custom_resource_id'])
    end

    def render_articles_from_rss_feed(url, count = 3)
      require 'rss'
      require 'open-uri'
      output = []
      open(url.to_s.strip) do |rss|
        feed = RSS::Parser.parse(rss, false)
        feed.items.first(count).each do |item|
          output << item.title.strip + "\n" + item.link.strip
        end
      end
      output.join("\n\n")
    end

    def refresh_rss_feeds_cache
      bot = BotUser.smooch_user
      TeamBotInstallation.where(user_id: bot.id).each do |tbi|
        tbi.settings['smooch_workflows'].to_a.collect{ |w| w['smooch_custom_resources'].to_a }.flatten.reject{ |r| r.blank? }.each do |resource|
          next if resource['smooch_custom_resource_feed_url'].blank?
          begin
            content = self.render_articles_from_rss_feed(resource['smooch_custom_resource_feed_url'], resource['smooch_custom_resource_number_of_articles'])
            Rails.cache.write("smooch:rss_feed:#{Digest::MD5.hexdigest(resource['smooch_custom_resource_feed_url'])}:#{resource['smooch_custom_resource_number_of_articles']}", content)
          rescue StandardError => e
            self.notify_error(e, { bot: 'Smooch', operation: 'RSS Feed Update', team: tbi.team.slug }.merge(resource))
          end
        end
      end
      self.delay_for(15.minutes, retry: 0).refresh_rss_feeds_cache unless Rails.env.test? # Avoid infinite loop
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
