module TiplineResourceMutations
  MUTATION_TARGET = 'tipline_resource'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :uuid, GraphQL::Types::String, required: false
      argument :title, GraphQL::Types::String, required: false
      argument :content, GraphQL::Types::String, required: false
      argument :language, GraphQL::Types::String, required: false

      # Header
      argument :header_type, GraphQL::Types::String, required: false, camelize: false
      argument :header_overlay_text, GraphQL::Types::String, required: false, camelize: false

      # Content
      argument :content_type, GraphQL::Types::String, required: false, camelize: false

      # Dynamic resource: RSS Feed
      argument :rss_feed_url, GraphQL::Types::String, required: false, camelize: false
      argument :number_of_articles, GraphQL::Types::Int, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields
  end

  class Destroy < Mutations::DestroyMutation; end
end
