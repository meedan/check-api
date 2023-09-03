class AddAndRenameColumnsToTiplineResource < ActiveRecord::Migration[6.1]
  def change
    add_column :tipline_resources, :language, :string
    add_column :tipline_resources, :content_type, :string # 'static' or 'rss'
    add_column :tipline_resources, :header_type, :string, null: false, default: 'link_preview'
    add_column :tipline_resources, :header_file, :string
    add_column :tipline_resources, :header_overlay_text, :string
    add_column :tipline_resources, :header_media_url, :string
    rename_column :tipline_resources, :feed_url, :rss_feed_url  
  end
end
