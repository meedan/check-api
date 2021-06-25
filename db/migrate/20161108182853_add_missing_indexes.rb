class AddMissingIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :medias, :user_id
  end
end
