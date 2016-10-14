class RemoveTitleAndDescriptionFromMedias < ActiveRecord::Migration
  def change
    remove_column :medias, :title
    remove_column :medias, :description
  end
end
