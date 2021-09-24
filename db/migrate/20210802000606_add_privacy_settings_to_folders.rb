class AddPrivacySettingsToFolders < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :privacy, :integer, default: 0, null: false
  end
end
