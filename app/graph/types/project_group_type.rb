class ProjectGroupType < DefaultObject
  description "Project group type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :team, TeamType, null: true
  field :medias_count, GraphQL::Types::Int, null: true

  field :projects, ProjectType.connection_type, null: true
end
