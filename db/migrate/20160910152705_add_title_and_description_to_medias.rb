class AddTitleAndDescriptionToMedias < ActiveRecord::Migration[4.2]
  def change
    add_column :medias, :title, :string
    add_column :medias, :description, :string
  end
end
