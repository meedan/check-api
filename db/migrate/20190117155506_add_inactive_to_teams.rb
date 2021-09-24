class AddInactiveToTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :teams, :inactive, :boolean, default: false
    add_index :teams, :inactive
  end
end
