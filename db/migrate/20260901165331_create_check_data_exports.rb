class CreateCheckDataExports < ActiveRecord::Migration[6.1]
  def change
    create_table :check_data_exports do |t|
      t.references :user, foreign_key: true
      t.references :team, foreign_key: true
      t.string :download_url
      t.datetime :generated_at
      t.datetime :expired_at

      t.timestamps
    end
  end
end
