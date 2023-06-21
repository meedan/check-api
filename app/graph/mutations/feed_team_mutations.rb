module FeedTeamMutations
  MUTATION_TARGET = 'feed_team'.freeze
  PARENTS = ['feed'].freeze

  class Update < Mutations::UpdateMutation
    argument :saved_search_id, Integer, required: false, camelize: false
    argument :shared, String, required: false
    argument :requests_filters, Boolean, required: false, camelize: false
  end
end
