class ClusterType < DefaultObject
  description "Cluster type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true

  field :first_item_at, GraphQL::Types::Int, null: true

  def first_item_at
    object.first_item_at.to_i
  end

  field :last_item_at, GraphQL::Types::Int, null: true

  def last_item_at
    object.last_item_at.to_i
  end
end
