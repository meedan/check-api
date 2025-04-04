class AddFirstManualResponseAtAndLastManualResponseAtToTiplineRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :tipline_requests, :first_manual_response_at, :integer, null: false, default: 0
    add_column :tipline_requests, :last_manual_response_at, :integer, null: false, default: 0
  end
end
