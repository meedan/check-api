class CreateBotResources < ActiveRecord::Migration
  def change
    create_table :bot_resources do |t|
      t.string :uuid, null: false, default: ''
      t.string :title, null: false, default: ''
      t.string :content, null: false, default: ''
      t.string :feed_url
      t.integer :number_of_articles, default: 3
      t.references :team
      t.timestamps
    end
    add_index :bot_resources, :uuid, unique: true
    add_index :bot_resources, :team_id
  end
end
