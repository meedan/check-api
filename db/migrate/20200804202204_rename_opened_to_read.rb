class RenameOpenedToRead < ActiveRecord::Migration
  def change
    rename_column :project_medias, :opened, :read
  end
end
