class CreateTiplineNewsletters < ActiveRecord::Migration[5.2]
  def change
    create_table :tipline_newsletters do |t|
      t.string :header_type, null: false, default: 'none'
      t.string :header_file
      t.string :header_overlay_text
      t.string :header_media_url
      t.string :introduction, null: false
      t.string :content_type, null: false, default: 'static' # Or 'rss'
      t.string :rss_feed_url
      t.text :first_article
      t.text :second_article
      t.text :third_article
      t.integer :number_of_articles, null: false, default: 0
      t.string :footer
      t.string :send_every
      t.date :send_on
      t.string :timezone
      t.time :time
      t.datetime :last_sent_at
      t.datetime :last_scheduled_at
      t.integer :last_scheduled_by_id
      t.string :language, null: false
      t.boolean :enabled, null: false, default: false
      t.references :team, null: false, index: true
      t.timestamps null: false
    end
    add_index :tipline_newsletters, [:team_id, :language], unique: true
  end
end
