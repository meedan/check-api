class CheckDataExportType < DefaultObject
  description 'CheckDataExport type'

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :status, GraphQL::Types::String, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :user, UserType, null: true
  field :team, PublicTeamType, null: true
end
