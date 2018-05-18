class AddBridgeReaderBot < ActiveRecord::Migration
  def change
    create_table :bot_bridge_readers do |t|
      t.string :name
      t.timestamps null: false
    end
    bot = Bot::BridgeReader.new
    bot.name = 'Bridge Reader Bot'
    bot.save!
  end
end
