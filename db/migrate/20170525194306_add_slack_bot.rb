class AddSlackBot < ActiveRecord::Migration
  def change
    create_table :bot_slacks do |t|
      t.string :name
      t.text :settings
      t.timestamps null: false
    end
    bot = Bot::Slack.new
    bot.name = 'Slack Bot'
    bot.save!
  end
end
