class ExplainerItemType < DefaultObject
  description 'Explainer item type'

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :explainer_id, GraphQL::Types::Int, null: false
  field :project_media_id, GraphQL::Types::Int, null: false
  field :explainer, ExplainerType, null: false
  field :project_media, ProjectMediaType, null: false
end
