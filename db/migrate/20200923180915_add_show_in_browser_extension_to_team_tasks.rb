class AddShowInBrowserExtensionToTeamTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :team_tasks, :show_in_browser_extension, :boolean, null: false, default: true
  end
end
