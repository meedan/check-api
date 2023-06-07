class ProjectGroupType < DefaultObject
  description "Project group type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :title, String, null: true
  field :description, String, null: true
  field :team_id, Integer, null: true
  field :team, TeamType, null: true
  field :medias_count, Integer, null: true

  field :projects, ProjectType.connection_type, null: true
end
