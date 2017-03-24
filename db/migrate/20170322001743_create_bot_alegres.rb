class CreateBotAlegres < ActiveRecord::Migration
  def change
    create_table :bot_alegres do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
