class CreateBlockedTiplineUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :blocked_tipline_users do |t|
      t.string :uid, null: false
      t.timestamps
    end
    add_index :blocked_tipline_users, :uid, unique: true
  end
end
