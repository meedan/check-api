module ExplainerItemMutations
  MUTATION_TARGET = 'explainer_item'.freeze
  PARENTS = ['explainer', 'project_media'].freeze

  class Create < Mutations::CreateMutation
    argument :explainer_id, GraphQL::Types::Int, required: true
    argument :project_media_id, GraphQL::Types::Int, required: true
  end

  class SendExplainersToPreviousRequests < Mutations::BaseMutation
    argument :dbid, GraphQL::Types::Int, required: true
    # range represent how many days ago the request was sent i.e (1, 7 , 30)
    argument :range, GraphQL::Types::Int, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(dbid:, range:)
      begin
        explainer_item = ExplainerItem.find_if_can(dbid, context[:ability])
        explainer_item.send_explainers_to_previous_requests(range)
        { success: true }
      rescue
        { success: false }
      end
    end
  end

  class Destroy < Mutations::DestroyMutation; end
end
