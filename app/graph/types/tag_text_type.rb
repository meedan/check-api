module Types
  class TagTextType < DefaultObject
    description 'Tag text type'

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :text, String, null: true
    field :tags_count, Integer, null: true
  end
end
