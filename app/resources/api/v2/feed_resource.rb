module Api
  module V2
    class FeedResource < BaseResource
      model_name 'ProjectMedia'

      attributes :title
      filter :type, default: 'text', apply: ->(records, _value, _options) { records }
      filter :query, apply: ->(records, _value, _options) { records }

      def self.records(options = {})
        team_ids = self.workspaces(options).map(&:id)
        filters = options[:filters] || {}
        query = filters.dig(:query, 0)
        type = filters.dig(:type, 0)
        return ProjectMedia.none if team_ids.blank? || query.blank?
        results = Bot::Smooch.search_for_similar_published_fact_checks(type, query, team_ids)
        ProjectMedia.where(id: results.map(&:id))
      end

      def self.count(filters, options = {})
        self.records(options.merge(filters: filters)).count
      end
    end
  end
end
