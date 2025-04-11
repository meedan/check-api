module ExplainerItemMutations
  MUTATION_TARGET = 'explainer_item'.freeze
  PARENTS = ['explainer', 'project_media'].freeze

  class Create < Mutations::CreateMutation
    argument :explainer_id, GraphQL::Types::Int, required: true
    argument :project_media_id, GraphQL::Types::Int, required: true
  end

  class SendExplainersToPreviousRequests < Mutations::BaseMutation
    argument :id, GraphQL::Types::Int, required: true
    argument :range, GraphQL::Types::Int, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(id:, range:)
      explainer_item = ExplainerItem.find_if_can(id, context[:ability])
      explainer_item.send_explainers_to_previous_requests(range)
      { success: true }
    end
  end

  class Destroy < Mutations::DestroyMutation; end
end
