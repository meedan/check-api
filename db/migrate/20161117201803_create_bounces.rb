class CreateBounces < ActiveRecord::Migration[4.2]
  def change
    create_table :bounces do |t|
      t.string :email, null: false
      t.timestamps null: false
    end
    add_index :bounces, :email, unique: true
  end
end
