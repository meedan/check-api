class TagTextType < DefaultObject
  description "Tag text type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :text, GraphQL::Types::String, null: true
  field :tags_count, GraphQL::Types::Int, null: true
end
