class CreateSources < ActiveRecord::Migration[4.2]
  def change
    create_table :sources do |t|
      t.belongs_to :user
      t.belongs_to :team
      t.string :name
      t.string :slogan
      t.string :avatar
      t.integer :archived, default: 0
      t.string :file
      t.integer :lock_version, default: 0, null: false
      t.timestamps null: false
    end
  end
end
