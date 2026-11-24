class CheckDataExportType < DefaultObject
  description 'CheckDataExport type'

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :status, GraphQL::Types::String, null: true
  field :user, UserType, null: true
  field :team, TeamType, null: true

  def team
    team = object.team
    ability = context[:ability] || Ability.new
    team if team && ability.can?(:read, team)
  end

  field :created_at, GraphQL::Types::String, null: true, camelize: false

  def created_at
    object.created_at.to_i.to_s
  end
end
