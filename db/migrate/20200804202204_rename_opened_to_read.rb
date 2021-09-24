class RenameOpenedToRead < ActiveRecord::Migration[4.2]
  def change
    rename_column :project_medias, :opened, :read
  end
end
