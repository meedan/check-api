class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.belongs_to :user, index: true
      t.belongs_to :source, index: true
      t.string :url
      t.column :data, :json
      t.timestamps null: false
    end
  end
end
