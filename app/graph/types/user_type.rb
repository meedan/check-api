class UserType < DefaultObject
  description "User type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :email, GraphQL::Types::String, null: true
  field :providers, JsonStringType, null: true
  field :profile_image, GraphQL::Types::String, null: true
  field :login, GraphQL::Types::String, null: true
  field :name, GraphQL::Types::String, null: true
  field :current_team_id, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :number_of_teams, GraphQL::Types::Int, null: true
  field :is_active, GraphQL::Types::Boolean, null: true
  field :accepted_terms, GraphQL::Types::Boolean, null: true
  field :last_accepted_terms_at, GraphQL::Types::String, null: true
  field :team_ids, [GraphQL::Types::Int, null: true], null: true
  field :last_active_at, GraphQL::Types::Int, null: true
  field :completed_signup, GraphQL::Types::Boolean, null: true
  field :source_id, GraphQL::Types::Int, null: true
  field :is_bot, GraphQL::Types::Boolean, null: true

  field :current_team, TeamType, null: true

  def current_team
    User.current == object ? object.current_team : nil
  end

  field :source, SourceType, null: true

  def source
    Source.find(object.source_id)
  end

  field :team_user, TeamUserType, null: true do
    argument :team_slug, GraphQL::Types::String, required: true, camelize: false
  end

  def team_user(team_slug:)
    tu = TeamUser
      .joins(:team)
      .where("teams.slug" => team_slug, :user_id => object.id)
      .last
    tu.nil? ? nil : TeamUser.find_if_can(tu.id, context[:ability])
  end

  field :team_users, TeamUserType.connection_type, null: true do
    argument :status, GraphQL::Types::String, required: false
  end

  def team_users(status: nil)
    return TeamUser.none unless object == User.current
    team_users = object.team_users
    team_users = team_users.where(status: status) if status
    team_users
  end
end
