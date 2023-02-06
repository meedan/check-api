class AddChannelToProjectMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :channel, :integer, default: 0
    add_index :project_medias, :channel
  end
end
