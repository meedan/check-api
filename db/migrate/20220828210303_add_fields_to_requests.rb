class AddFieldsToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :medias_count, :integer, null: false, default: 0
    add_column :requests, :requests_count, :integer, null: false, default: 0
    add_column :requests, :last_submitted_at, :datetime
  end
end
