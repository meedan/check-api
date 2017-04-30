class AddAvatarToBotAlegres < ActiveRecord::Migration
  def change
    add_column :bot_alegres, :avatar, :string
  end
end
