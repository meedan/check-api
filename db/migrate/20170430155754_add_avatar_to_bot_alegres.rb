class AddAvatarToBotAlegres < ActiveRecord::Migration[4.2]
  def change
    add_column :bot_alegres, :avatar, :string
  end
end
