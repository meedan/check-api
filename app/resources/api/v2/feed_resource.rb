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

      def self.records(options = {})
        team_ids = self.workspaces(options).map(&:id)
        filters = options[:filters] || {}
        query = filters.dig(:query, 0)
        type = filters.dig(:type, 0)
        after = filters.dig(:after, 0)
        after = Time.parse(after) unless after.blank?
        return ProjectMedia.none if team_ids.blank? || query.blank?
        results = Bot::Smooch.search_for_similar_published_fact_checks(type, CGI.unescape(query), team_ids, after)
        ProjectMedia.where(id: results.map(&:id))
      end

      def self.count(filters, options = {})
        self.records(options.merge(filters: filters)).count
      end
    end
  end
end
