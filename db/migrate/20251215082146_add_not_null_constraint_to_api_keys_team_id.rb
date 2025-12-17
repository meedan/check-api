class AddNotNullConstraintToApiKeysTeamId < ActiveRecord::Migration[6.1]
  def change
    change_column_null :api_keys, :team_id, false
  end
end
