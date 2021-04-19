module Api
  module V2
    class ReportResource < BaseResource
      model_name 'ProjectMedia'

      attributes :title, :description, :lead_image, :archived, :created_at, :media_id
      attribute :workspace_id, delegate: :team_id
      attribute :report_title, delegate: :analysis_title
      attribute :report_body, delegate: :analysis_description
      attribute :article_link, delegate: :analysis_published_article_url
      attribute :report_rating, delegate: :status
      attribute :published, delegate: :analysis_published_date
      attribute :original_media, delegate: :uploaded_file_url
      attribute :original_claim_title, delegate: :original_title
      attribute :original_claim_body, delegate: :original_description
      attribute :original_claim_link, delegate: :link
      attribute :original_claim_author, delegate: :source_name
      attribute :similar_media, delegate: :linked_items_count
      attribute :requests, delegate: :requests_count
      attribute :check_url, delegate: :full_url
      attribute :organization, delegate: :team_name
      attribute :tags, delegate: :tags_as_sentence
      attribute :media_type, delegate: :type_of_media

      def self.records(options = {})
        team_ids = self.workspaces(options).map(&:id)
        conditions = { team_id: team_ids }
        result = ProjectMedia
        filters = options[:filters] || {}

        # Check filters
        conditions[:archived] = filters[:archived] if filters.has_key?(:archived)
        result = result.joins(:media).where('medias.type' => filters[:media_type]) if filters.has_key?(:media_type)

        # Filtering by similar items, from Alegre
        text = filters[:similar_to_text]
        unless text.blank?
          ids = begin
                  threshold = filters[:similarity_threshold] ? filters[:similarity_threshold][0].to_f : nil
                  organization_ids = filters[:similarity_organization_ids].blank? ? team_ids : filters[:similarity_organization_ids].flatten.map(&:to_i)
                  fields = filters[:similarity_fields].blank? ? nil : filters[:similarity_fields].to_a.flatten
                  Bot::Alegre.get_items_from_similar_text(organization_ids, text[0], fields, threshold).keys.uniq
                rescue StandardError => e
                  Bot::Alegre.notify_error(e, options, RequestStore[:request])
                  nil
                end
          conditions[:id] = ids || [0]
        end

        result.where(conditions)
      end

      def self.count(filters, options = {})
        self.records(options.merge(filters: filters)).count
      end

      # Just declaring the filters used for similarity - the logic is above in the "records" method definition
      filter :media_type, apply: ->(records, _value, _options) { records }
      filter :archived, apply: ->(records, _value, _options) { records }
      filter :similar_to_text, apply: ->(records, _value, _options) { records }
      filter :similarity_fields, apply: ->(records, _value, _options) { records }
      filter :similarity_threshold, apply: ->(records, _value, _options) { records }
      filter :similarity_organization_ids, apply: ->(records, _value, _options) { records }
    end
  end
end
