class AddDataPointsToFeeds < ActiveRecord::Migration[6.1]
  def change
    add_column :feeds, :data_points, :integer, array: true, default: []
  end
end
