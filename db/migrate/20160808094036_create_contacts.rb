class CreateContacts < ActiveRecord::Migration[4.2]
  def change
    create_table :contacts do |t|
      t.belongs_to :team, index: true
      t.string :location
      t.string :phone
      t.string :web

      t.timestamps null: false
    end
  end
end
