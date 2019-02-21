class AddInactiveToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :inactive, :boolean, default: false
    add_index :teams, :inactive
  end
end
