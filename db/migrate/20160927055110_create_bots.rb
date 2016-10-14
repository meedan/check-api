class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :name
      t.string :avatar

      t.timestamps null: false
    end
    # Create a Pender bot
    Bot.create(name: 'Pender')
  end
end
