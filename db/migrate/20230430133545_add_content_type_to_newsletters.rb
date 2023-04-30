class AddContentTypeToNewsletters < ActiveRecord::Migration[6.0]
  def change
    add_column :tipline_newsletters, :content_type, :string, null: false, default: 'static' # Or 'rss'
  end
end
