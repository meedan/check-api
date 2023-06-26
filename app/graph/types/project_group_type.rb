class ProjectGroupType < DefaultObject
  description "Project group type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Integer, null: true
  field :title, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :team_id, GraphQL::Types::Integer, null: true
  field :team, TeamType, null: true
  field :medias_count, GraphQL::Types::Integer, null: true

  field :projects, ProjectType.connection_type, null: true
end
