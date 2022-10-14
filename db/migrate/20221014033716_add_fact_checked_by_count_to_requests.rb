class AddFactCheckedByCountToRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :requests, :fact_checked_by_count, :integer, null: false, default: 0
  end
end
