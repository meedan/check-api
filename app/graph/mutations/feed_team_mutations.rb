module FeedTeamMutations
  MUTATION_TARGET = 'feed_team'.freeze
  PARENTS = ['feed'].freeze

  class Update < Mutations::UpdateMutation
    argument :media_saved_search_id, GraphQL::Types::Int, required: false, camelize: false
    argument :article_saved_search_id, GraphQL::Types::Int, required: false, camelize: false
    argument :shared, GraphQL::Types::Boolean, required: false
    argument :requests_filters, JsonStringType, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
