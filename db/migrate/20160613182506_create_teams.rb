class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name
      t.string :logo
      t.boolean :private, default: false
      t.boolean :archived, default: false
      t.timestamps null: false
    end
  end
end
