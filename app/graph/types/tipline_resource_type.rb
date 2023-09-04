class TiplineResourceType < DefaultObject
  description "TiplineResource type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :uuid, GraphQL::Types::String, null: true
  field :header_type, GraphQL::Types::String, null: true
  field :header_file_url, GraphQL::Types::String, null: true
  field :header_overlay_text, GraphQL::Types::String, null: true
  field :content_type, GraphQL::Types::String, null: true
  field :rss_feed_url, GraphQL::Types::String, null: true
  field :content, GraphQL::Types::String, null: true
  field :number_of_articles, GraphQL::Types::Int, null: true
  field :language, GraphQL::Types::String, null: true
  field :team, TeamType, null: true
end
