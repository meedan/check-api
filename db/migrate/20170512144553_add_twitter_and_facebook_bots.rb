class AddTwitterAndFacebookBots < ActiveRecord::Migration
  def change
    create_table :bot_twitters do |t|
      t.string :name
      t.timestamps null: false
    end
    bot = Bot::Twitter.new
    bot.name = 'Twitter Bot'
    bot.save!

    create_table :bot_facebooks do |t|
      t.string :name
      t.timestamps null: false
    end
    bot = Bot::Facebook.new
    bot.name = 'Facebook Bot'
    bot.save!
  end
end
