class AddFileToMedias < ActiveRecord::Migration
  def change
    add_column :medias, :file, :string
  end
end
