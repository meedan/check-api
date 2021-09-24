class TeamsPrivateByDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:teams, :private, true)
  end
end
