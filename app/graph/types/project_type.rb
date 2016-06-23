ProjectType = GraphQL::ObjectType.define do
  name 'Project'
  description 'Project type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Project')
  field :updated_at, types.String
  field :created_at, types.String
  field :lead_image, types.String
  field :description, types.String
  field :title, types.String
  field :user_id, types.Int
  field :user do
    type UserType

    resolve -> (project, _args, _ctx) {
      project.user
    }
  end
  connection :medias, -> { MediaType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.medias
    }
  end

  connection :project_sources, -> { ProjectSourceType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.project_sources
    }
  end

  connection :sources, -> { SourceType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.sources
    }
  end

# End of fields
end
