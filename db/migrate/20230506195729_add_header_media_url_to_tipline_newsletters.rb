class AddHeaderMediaUrlToTiplineNewsletters < ActiveRecord::Migration[6.0]
  def change
    add_column :tipline_newsletters, :header_media_url, :string
  end
end
