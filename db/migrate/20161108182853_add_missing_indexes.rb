class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :medias, :user_id
  end
end
