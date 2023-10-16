class FeedInvitationType < DefaultObject
  description "Feed invitation type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: false
  field :feed_id, GraphQL::Types::Int, null: false
  field :feed, FeedType, null: false
  field :user_id, GraphQL::Types::Int, null: false
  field :user, UserType, null: false
  field :state, GraphQL::Types::String, null: false
  field :email, GraphQL::Types::String, null: false
end
