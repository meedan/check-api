module Api
  module V2
    class FeedResource < BaseResource
      model_name 'ProjectMedia'

      attribute :claim, delegate: :claim_description_content
      attribute :title, delegate: :fact_check_title
      attribute :summary, delegate: :fact_check_summary
      attribute :url, delegate: :published_url
      attribute :report_title, delegate: :report_text_title
      attribute :report_summary, delegate: :report_text_content
      attribute :organization, delegate: :team_name
      attribute :rating, delegate: :status

      filter :type, default: 'text', apply: ->(records, _value, _options) { records }
      filter :query, apply: ->(records, _value, _options) { records }

      def self.records(options = {})
        team_ids = self.workspaces(options).map(&:id)
        filters = options[:filters] || {}
        query = filters.dig(:query, 0)
        type = filters.dig(:type, 0)
        return ProjectMedia.none if team_ids.blank? || query.blank?
        results = Bot::Smooch.search_for_similar_published_fact_checks(type, CGI.unescape(query), team_ids)
        ProjectMedia.where(id: results.map(&:id))
      end

      def self.count(filters, options = {})
        self.records(options.merge(filters: filters)).count
      end
    end
  end
end
