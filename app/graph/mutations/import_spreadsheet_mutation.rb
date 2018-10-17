ImportSpreadsheetMutation = GraphQL::Relay::Mutation.define do
  name 'ImportSpreadsheet'

  input_field :spreadsheet_url, !types.String
  input_field :user_id, types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    Team.import_spreadsheet_in_background(inputs[:spreadsheet_url], inputs[:user_id].to_i)
    { success: true }
  }
end
