class AddFileToMedias < ActiveRecord::Migration[4.2]
  def change
    add_column :medias, :file, :string
  end
end
