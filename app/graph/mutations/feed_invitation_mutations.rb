module FeedInvitationMutations
  MUTATION_TARGET = 'feed_invitation'.freeze
  PARENTS = ['feed'].freeze

  class Create < Mutations::CreateMutation
    argument :email, GraphQL::Types::String, required: true
    argument :feed_id, GraphQL::Types::Int, required: true, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end

  class Accept < Mutations::UpdateMutation
    argument :id, GraphQL::Types::Int, required: true
    argument :team_id, GraphQL::Types::Int, required: true, camelize: false

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(id: nil, team_id: nil)
      success = false
      feed_invitation = FeedInvitation.find_if_can(id, context[:ability])
      if User.current && Team.current && User.current.team_ids.include?(team_id) && feed_invitation.email == User.current.email
        feed_invitation.accept!(team_id)
        success = true
      end
      { success: success }
    end
  end
  
  class Reject < Mutations::BaseMutation
    argument :id, GraphQL::Types::Int, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(id: nil)
      success = false
      feed_invitation = FeedInvitation.find_if_can(id, context[:ability])
      if User.current && Team.current && feed_invitation.email == User.current.email && feed_invitation.state == 'invited'
        feed_invitation.reject!
        success = true
      end
      { success: success }
    end
  end
end
