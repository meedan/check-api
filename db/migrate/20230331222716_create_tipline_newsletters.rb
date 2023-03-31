class CreateTiplineNewsletters < ActiveRecord::Migration[5.2]
  def change
    create_table :tipline_newsletters do |t|
      t.string :introduction, null: false
      t.string :rss_feed_url
      t.text :first_article
      t.text :second_article
      t.text :third_article
      t.integer :number_of_articles, null: false, default: 0
      t.string :send_every
      t.string :timezone
      t.time :time
      t.datetime :last_sent_at
      t.string :language
      t.references :team, null: false, index: true
      t.timestamps null: false
    end
  end
end
