class CreateFeeds < ActiveRecord::Migration[5.2]
  def change
    create_table :feeds do |t|
      t.string :name, null: false
      t.jsonb :filters, default: {}
      t.jsonb :settings, default: {}
      t.timestamps
    end
  end
end
