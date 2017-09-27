class AddLimitsToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :limits, :text
  end
end
