class AddSettingsToTeamsAndProjects < ActiveRecord::Migration
  def change
    add_column :projects, :settings, :text
    add_column :teams, :settings, :text
  end
end
