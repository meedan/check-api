class TiplineSearchResultType < DefaultObject
  description "Represents a search result for the tipline"

  field :title, GraphQL::Types::String, null: false
  field :body, GraphQL::Types::String, null: true
  field :image_url, GraphQL::Types::String, null: true
  field :language, GraphQL::Types::String, null: true
  field :url, GraphQL::Types::String, null: true
  field :type, GraphQL::Types::String, null: false
  field :format, GraphQL::Types::String, null: false
end
