class CreateBots < ActiveRecord::Migration
  def change
    create_table :bot_bots do |t|
      t.string :name
      t.string :avatar

      t.timestamps null: false
    end
    # Create a Pender bot
    Bot::Bot.create(name: 'Pender')
  end
end
