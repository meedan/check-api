class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name
      t.string :logo
      t.boolean :private, default: false
      t.integer :archived, default: 0
      t.timestamps null: false
    end
  end
end
