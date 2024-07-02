module ExplainerItemMutations
  MUTATION_TARGET = 'explainer_item'.freeze
  PARENTS = ['explainer', 'project_media'].freeze

  class Create < Mutations::CreateMutation
    argument :explainer_id, GraphQL::Types::Int, required: true
    argument :project_media_id, GraphQL::Types::Int, required: true
  end

  class Destroy < Mutations::DestroyMutation; end
end
