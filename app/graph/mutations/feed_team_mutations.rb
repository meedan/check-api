module FeedTeamMutations
  MUTATION_TARGET = 'feed_team'.freeze
  PARENTS = ['feed'].freeze

  class Update < Mutations::UpdateMutation
    argument :saved_search_id, GraphQL::Types::Int, required: false, camelize: false, as: :media_saved_search_id
    argument :shared, GraphQL::Types::Boolean, required: false
    argument :requests_filters, JsonStringType, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
