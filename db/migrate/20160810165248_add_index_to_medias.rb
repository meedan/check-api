class AddIndexToMedias < ActiveRecord::Migration
  def change
    #add_column :medias, :url, :string
    add_index :medias, :url, unique: true
  end
end
