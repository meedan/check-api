module FeedTeamMutations
  MUTATION_TARGET = 'feed_team'.freeze
  PARENTS = ['feed'].freeze

  class Update < Mutations::UpdateMutation
    argument :saved_search_id, GraphQL::Types::Int, required: false, camelize: false
    argument :shared, GraphQL::Types::String, required: false
    argument :requests_filters, GraphQL::Types::Boolean, required: false, camelize: false
  end
end
