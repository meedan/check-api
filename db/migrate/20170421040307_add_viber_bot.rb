class AddViberBot < ActiveRecord::Migration
  def change
    create_table :bot_vibers do |t|
      t.string :name
      t.timestamps null: false
    end
    bot = Bot::Viber.new
    bot.name = 'Viber Bot'
    bot.save!
  end
end
