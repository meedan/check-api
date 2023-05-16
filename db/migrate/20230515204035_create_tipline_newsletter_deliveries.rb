class CreateTiplineNewsletterDeliveries < ActiveRecord::Migration[5.2]
  def change
    create_table :tipline_newsletter_deliveries do |t|
      t.integer :recipients_count, null: false, default: 0
      t.text :content, null: false
      t.datetime :started_sending_at, null: false
      t.datetime :finished_sending_at, null: false
      t.references :tipline_newsletter, null: false, index: true
      t.timestamps null: false
    end
  end
end
