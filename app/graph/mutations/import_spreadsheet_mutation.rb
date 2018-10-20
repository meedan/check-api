ImportSpreadsheetMutation = GraphQL::Relay::Mutation.define do
  name 'ImportSpreadsheet'

  input_field :spreadsheet_url, !types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    team = Team.current
    raise I18n.t('team_import.team_not_present') if !team

    user = User.current
    raise I18n.t('team_import.user_not_present') if !user

    ability ||= Ability.new
    raise I18n.t('team_import.user_not_authorized') if ability.cannot?(:import_spreadsheet, team)

    Team.import_spreadsheet_in_background(inputs[:spreadsheet_url], team.id, user.id)
    { success: true }
  }
end
