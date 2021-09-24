class CreateAccounts < ActiveRecord::Migration[4.2]
  def change
    create_table :accounts do |t|
      t.belongs_to :user, index: true
      t.belongs_to :source, index: true
      t.string :url
      if ApplicationRecord.connection.class.name === 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
        t.json :data
      else
        t.text :data
      end
      t.timestamps null: false
    end
  end
end
