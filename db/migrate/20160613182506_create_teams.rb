class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.name :string
      t.description :text
      t.logo :string
      t.archived :boolean
      t.timestamps null: false
    end
  end
end
