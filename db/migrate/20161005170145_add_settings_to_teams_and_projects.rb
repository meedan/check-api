class AddSettingsToTeamsAndProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :settings, :text
    add_column :teams, :settings, :text
  end
end
