module Api
  module V2
    class FeedResource < BaseResource
      model_name 'ProjectMedia'

      attribute :claim, delegate: :claim_description_content
      attribute :claim_context, delegate: :claim_description_context
      attribute :claim_tags, delegate: :tags_as_sentence
      attribute :fact_check_title
      attribute :fact_check_summary
      attribute :fact_check_published_on
      attribute :fact_check_rating, delegate: :status
      attribute :published_article_url, delegate: :published_url
      attribute :organization, delegate: :team_name

      filter :type, default: 'text', apply: ->(records, _value, _options) { records }
      filter :query, apply: ->(records, _value, _options) { records }
      filter :after, apply: ->(records, _value, _options) { records }
      filter :feed_id, apply: ->(records, _value, _options) { records }
      filter :webhook_url, apply: ->(records, _value, _options) { records }

      paginator :none

      def self.records(options = {}, skip_save_request = false)
        team_ids = self.workspaces(options).map(&:id)
        Team.current ||= team_ids[0]
        filters = options[:filters] || {}
        query = filters.dig(:query).to_a.join(',')
        query = CGI.unescape(query)
        type = filters.dig(:type, 0)
        webhook_url = filters.dig(:webhook_url, 0)
        after = filters.dig(:after, 0)
        after = Time.parse(after) unless after.blank?
        feed_id = filters.dig(:feed_id, 0).to_i
        return ProjectMedia.none if team_ids.blank? || query.blank?

        if feed_id > 0
          get_results_from_feed_teams(team_ids, feed_id, query, type, after, webhook_url, skip_save_request)
        elsif ApiKey.current
          get_results_from_api_key_teams(type, query, after)
        else
          ProjectMedia.none
        end
      end

      def self.get_results_from_api_key_teams(type, query, after)
        RequestStore.store[:pause_database_connection] = true # Release database connection during Bot::Alegre.request_api
        team_ids = ApiKey.current.bot_user.team_ids
        Bot::Smooch.search_for_similar_published_fact_checks(type, query, team_ids, after)
      end

      def self.get_results_from_feed_teams(team_ids, feed_id, query, type, after, webhook_url, skip_save_request)
        return ProjectMedia.none unless can_read_feed?(feed_id, team_ids)
        feed = Feed.find(feed_id)
        RequestStore.store[:pause_database_connection] = true # Release database connection during Bot::Alegre.request_api
        RequestStore.store[:smooch_bot_settings] = feed.get_smooch_bot_settings.to_h
        results = Bot::Smooch.search_for_similar_published_fact_checks(type, query, feed.team_ids, after, feed_id)
        Feed.delay({ retry: 0, queue: 'feed' }).save_request(feed_id, type, query, webhook_url, results.to_a.map(&:id)) unless skip_save_request
        results
      end

      # Make sure that we keep the same order returned by the "records" method above
      def self.apply_sort(records, _order_options, _context = {})
        return ProjectMedia.none if records.size == 0
        ProjectMedia.where(id: records.map(&:id)).order(Arel.sql("array_position(ARRAY[#{records.map(&:id).join(', ')}], id)"))
      end

      def self.count(filters, options = {})
        self.records(options.merge(filters: filters), true).count
      end

      # The feed must be published and the teams for which this API key has access to must be part of the feed and sharing content with it
      def self.can_read_feed?(feed_id, team_ids)
        !Feed.where(id: feed_id, published: true).last.nil? && !(FeedTeam.where(feed_id: feed_id, shared: true).map(&:team_id) & team_ids).empty?
      end
    end
  end
end
