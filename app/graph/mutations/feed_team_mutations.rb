module FeedTeamMutations
  MUTATION_TARGET = 'feed_team'.freeze
  PARENTS = ['feed'].freeze

  class Update < UpdateMutation
    argument :filters, JsonString, required: false
    argument :shared, String, required: false
    argument :requests_filters, Boolean, required: false, camelize: false
  end
end
