class CreateAccounts < ActiveRecord::Migration[4.2]
  def change
    create_table :accounts do |t|
      t.belongs_to :user, index: true
      t.belongs_to :team
      t.string :url
      t.text :omniauth_info
      t.string :uid
      t.string :provider
      t.string :token
      t.string :email
      t.timestamps null: false
    end
    add_index :accounts, [:uid, :provider, :token, :email]
    add_index :accounts, :url, unique: true
  end
end
