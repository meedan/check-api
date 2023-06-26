module TiplineNewsletterMutations
  MUTATION_TARGET = 'tipline_newsletter'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :enabled, GraphQL::Types::Boolean, required: false
      argument :introduction, GraphQL::Types::String, required: false
      argument :language, GraphQL::Types::String, required: false

      # Header
      argument :header_type, GraphQL::Types::String, required: false, camelize: false
      argument :header_overlay_text, GraphQL::Types::String, required: false, camelize: false

      # Content
      argument :content_type, GraphQL::Types::String, required: false, camelize: false

      # Dynamic newsletter: RSS Feed
      argument :rss_feed_url, GraphQL::Types::String, required: false, camelize: false
      argument :number_of_articles, GraphQL::Types::Integer, required: false, camelize: false

      # Static newsletter: Articles
      argument :first_article, GraphQL::Types::String, required: false, camelize: false
      argument :second_article, GraphQL::Types::String, required: false, camelize: false
      argument :third_article, GraphQL::Types::String, required: false, camelize: false

      # Footer
      argument :footer, GraphQL::Types::String, required: false

      # Schedule
      argument :send_every, JsonString, required: false, camelize: false
      argument :send_on, GraphQL::Types::String, required: false, camelize: false
      argument :timezone, GraphQL::Types::String, required: false
      argument :time, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields
  end
end
