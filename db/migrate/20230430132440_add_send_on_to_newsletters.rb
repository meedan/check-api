class AddSendOnToNewsletters < ActiveRecord::Migration[6.0]
  def change
    add_column :tipline_newsletters, :send_on, :date
  end
end
