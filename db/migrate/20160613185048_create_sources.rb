class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.belongs_to :user, index: true
      t.string :name
      t.string :slogan
      t.string :avatar
      t.timestamps null: false
    end
  end
end
