class CreateMedia < ActiveRecord::Migration
  def change
    create_table :media do |t|
      t.belongs_to :user
      t.belongs_to :project, index: true
      t.belongs_to :account, index: true
      t.string :url
      t.json :data
      t.timestamps null: false
    end
  end
end
