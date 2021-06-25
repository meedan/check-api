class AddIndexesForProjectAndTeam < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :id
    add_index :teams, :id
  end
end
