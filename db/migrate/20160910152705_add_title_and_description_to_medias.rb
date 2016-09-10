class AddTitleAndDescriptionToMedias < ActiveRecord::Migration
  def change
    add_column :medias, :title, :string
    add_column :medias, :description, :string
  end
end
