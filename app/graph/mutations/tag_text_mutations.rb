module TagTextMutations
  MUTATION_TARGET = 'tag_text'.freeze
  PARENTS = ['team'].freeze

  class Create < Mutations::CreateMutation
    argument :team_id, GraphQL::Types::Integer, required: true, camelize: false
    argument :text, GraphQL::Types::String, required: true
  end

  class Update < Mutations::UpdateMutation
    argument :text, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
