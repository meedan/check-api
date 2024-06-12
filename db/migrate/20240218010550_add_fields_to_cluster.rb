class AddFieldsToCluster < ActiveRecord::Migration[6.1]
  def change
    add_column :clusters, :team_ids, :integer, array: true, null: false, default: []
    add_column :clusters, :channels, :integer, array: true, null: false, default: []
    add_column :clusters, :media_count, :integer, null: false, default: 0
    add_column :clusters, :requests_count, :integer, null: false, default: 0
    add_column :clusters, :fact_checks_count, :integer, null: false, default: 0
    add_column :clusters, :last_request_date, :datetime
    add_column :clusters, :last_fact_check_date, :datetime
  end
end
