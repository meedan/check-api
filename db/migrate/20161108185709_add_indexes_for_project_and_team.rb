class AddIndexesForProjectAndTeam < ActiveRecord::Migration
  def change
    add_index :projects, :id
    add_index :teams, :id
  end
end
