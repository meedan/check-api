class AddUserIdToRelationship < ActiveRecord::Migration
  def change
    add_column(:relationships, :user_id, :integer) unless column_exists?(:relationships, :user_id)
  end
end
