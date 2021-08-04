class AddPrivacySettingsToFolders < ActiveRecord::Migration
  def change
    add_column :projects, :privacy, :integer, default: 0, null: false
  end
end
