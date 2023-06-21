module FeedTeamMutations
  MUTATION_TARGET = 'feed_team'.freeze
  PARENTS = ['feed'].freeze

  class Update < Mutation::Update
    argument :filters, JsonString, required: false
    argument :shared, String, required: false
    argument :requests_filters, Boolean, required: false, camelize: false
  end
end
