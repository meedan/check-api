class CreateMedias < ActiveRecord::Migration[4.2]
  def change
    create_table :medias do |t|
      t.belongs_to :user
      t.belongs_to :account, index: true
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
