class TagTextType < DefaultObject
  description "Tag text type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Integer, null: true
  field :text, GraphQL::Types::String, null: true
  field :tags_count, GraphQL::Types::Integer, null: true
end
