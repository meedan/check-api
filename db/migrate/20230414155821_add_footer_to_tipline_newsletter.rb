class AddFooterToTiplineNewsletter < ActiveRecord::Migration[5.2]
  def change
    add_column :tipline_newsletters, :footer, :string
  end
end
