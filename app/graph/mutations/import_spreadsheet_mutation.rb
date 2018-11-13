ImportSpreadsheetMutation = GraphQL::Relay::Mutation.define do
  name 'ImportSpreadsheet'

  input_field :spreadsheet_url, !types.String
  input_field :team_id, !types.Int
  input_field :user_id, !types.Int

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    team = Team.find_by_id(inputs[:team_id])
    raise I18n.t('team_import.team_not_present') if !team

    user = User.find_by_id(inputs[:user_id])
    raise I18n.t('team_import.user_not_present') if !user

    ability = Ability.new(user)
    raise I18n.t('team_import.user_not_authorized') if ability.cannot?(:import_spreadsheet, team)

    Team.import_spreadsheet_in_background(inputs[:spreadsheet_url], team.id, user.id)
    { success: true }
  }
end
