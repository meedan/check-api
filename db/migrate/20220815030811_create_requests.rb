class CreateRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :requests do |t|
      t.references :feed, null: false, foreign_key: true, index: true
      t.string :request_type, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
