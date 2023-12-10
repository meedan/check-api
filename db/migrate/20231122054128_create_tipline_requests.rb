class CreateTiplineRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :tipline_requests do |t|
      t.string :language, null: false, index: true
      t.string :tipline_user_uid, index: true
      t.string :platform, null: false, index: true
      t.string :smooch_request_type, null: false
      t.string :smooch_resource_id, null: true
      t.string :smooch_message_id, null: true, default: ''
      t.string :smooch_conversation_id, null: true
      t.jsonb :smooch_data, null: false, default: {}
      t.references :associated, polymorphic: true, null: false
      t.references :team, null: false
      t.references :user
      t.integer :smooch_report_received_at, default: 0
      t.integer :smooch_report_update_received_at, default: 0
      t.integer :smooch_report_correction_sent_at, default: 0
      t.integer :smooch_report_sent_at, default: 0
      t.timestamps
    end
    add_index :tipline_requests, [:associated_type, :associated_id]
    add_index :tipline_requests, :smooch_message_id, unique: true, where: "smooch_message_id IS NOT NULL AND smooch_message_id != ''"
  end
end
