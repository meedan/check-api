class RemoveTitleAndDescriptionFromMedias < ActiveRecord::Migration
  def change
    remove_column :medias, :title, :string
    remove_column :medias, :description, :string
  end
end
