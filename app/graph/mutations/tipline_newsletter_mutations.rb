module TiplineNewsletterMutations
  MUTATION_TARGET = 'tipline_newsletter'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :enabled, GraphQL::Types::Boolean, required: false
      argument :introduction, String, required: false
      argument :language, String, required: false

      # Header
      argument :header_type, String, required: false, camelize: false
      argument :header_overlay_text, String, required: false, camelize: false

      # Content
      argument :content_type, String, required: false, camelize: false

      # Dynamic newsletter: RSS Feed
      argument :rss_feed_url, String, required: false, camelize: false
      argument :number_of_articles, Integer, required: false, camelize: false

      # Static newsletter: Articles
      argument :first_article, String, required: false, camelize: false
      argument :second_article, String, required: false, camelize: false
      argument :third_article, String, required: false, camelize: false

      # Footer
      argument :footer, String, required: false

      # Schedule
      argument :send_every, JsonString, required: false, camelize: false
      argument :send_on, String, required: false, camelize: false
      argument :timezone, String, required: false
      argument :time, String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields
  end
end
