class RemoveTitleAndDescriptionFromMedias < ActiveRecord::Migration[4.2]
  def change
    remove_column :medias, :title
    remove_column :medias, :description
  end
end
