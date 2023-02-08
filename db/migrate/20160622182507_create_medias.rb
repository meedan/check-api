class CreateMedias < ActiveRecord::Migration[4.2]
  def change
    create_table :medias do |t|
      t.belongs_to :user
      t.belongs_to :account, index: true
      t.string :url
      t.string :file
      t.string :quote
      t.string :type
      t.timestamps null: false
    end
    add_index :medias, :url, unique: true
  end
end
