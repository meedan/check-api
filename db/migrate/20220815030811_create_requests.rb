class CreateRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :requests do |t|
      t.references :feed, null: false, foreign_key: true, index: true
      t.string :request_type, null: false
      t.text :content, null: false
      t.integer :request_id, foreign_key: true, index: true
      t.integer :media_id, foreign_key: true, index: true
      t.integer :fact_checked_by_count, null: false, default: 0
      t.integer :project_medias_count, null: false, default: 0
      t.integer :medias_count, null: false, default: 0
      t.integer :requests_count, null: false, default: 0
      t.datetime :last_submitted_at
      t.string :webhook_url
      t.datetime :last_called_webhook_at
      t.integer :subscriptions_count, null: false, default: 0
      t.timestamps
    end
  end
end
