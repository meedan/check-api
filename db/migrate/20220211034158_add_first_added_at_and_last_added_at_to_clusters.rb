class AddFirstAddedAtAndLastAddedAtToClusters < ActiveRecord::Migration[5.2]
  def change
    # add_column :clusters, :first_item_at, :datetime
    # add_column :clusters, :last_item_at, :datetime
    Cluster.reset_column_information
    Cluster.find_each do |c|
      c.project_medias.find_each do |pm|
        c.send(:update_timestamps, pm)
      end
    end
  end
end
