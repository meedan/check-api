class AddRequestIdAndMediaIdToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :request_id, :integer, foreign_key: true
    add_index :requests, :request_id
    add_column :requests, :media_id, :integer, foreign_key: true
    add_index :requests, :media_id
  end
end
