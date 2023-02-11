class CreateTiplineMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :tipline_messages do |t|
      t.integer :direction, default: 0
      t.string :language
      t.string :platform
      t.datetime :sent_at

      t.string :uid, index: true
      t.string :external_id
      t.jsonb :payload, default: {}

      t.references :team, null: false, index: true

      t.timestamps null: false

      t.index [:external_id], unique: true
      t.index [:team_id, :uid, :platform, :language, :sent_at, :direction], unique: true, name: 'index_tipline_message_uniqueness'
    end
  end
end
