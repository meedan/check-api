class CreateCheckDataExports < ActiveRecord::Migration[6.1]
  def change
    create_table :check_data_exports do |t|
      t.references :user, foreign_key: true
      t.references :team, foreign_key: true
      t.string :s3_key
      t.string :download_url, null: false
      t.datetime :generated_at
      t.datetime :expired_at
      t.boolean :auto_extend_url_expiry, default: false
      t.timestamps
    end
  end
end
