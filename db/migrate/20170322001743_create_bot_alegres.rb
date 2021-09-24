class CreateBotAlegres < ActiveRecord::Migration[4.2]
  def change
    create_table :bot_alegres do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
