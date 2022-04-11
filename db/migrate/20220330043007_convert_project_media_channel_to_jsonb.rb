class ConvertProjectMediaChannelToJsonb < ActiveRecord::Migration[5.2]
  def change
    remove_column :project_medias, :channel
    add_column :project_medias, :channel, :jsonb, default: { main:0 }
    add_index :project_medias, :channel
  end
end
