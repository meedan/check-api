class CreateAccounts < ActiveRecord::Migration[4.2]
  def change
    create_table :accounts do |t|
      t.belongs_to :user, index: true
      t.belongs_to :source, index: true
      t.string :url
      t.text :omniauth_info
      t.string :uid
      t.string :provider
      t.string :token
      t.string :email
      if ApplicationRecord.connection.class.name === 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
        t.json :data
      else
        t.text :data
      end
      t.timestamps null: false
    end
  end
end
