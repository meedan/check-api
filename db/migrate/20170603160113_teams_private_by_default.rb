class TeamsPrivateByDefault < ActiveRecord::Migration
  def change
    change_column_default(:teams, :private, true)
  end
end
