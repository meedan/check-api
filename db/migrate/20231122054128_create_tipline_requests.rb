class CreateTiplineRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :tipline_requests do |t|
      t.string :language
      t.string :tipline_user_uid, null: false, default: "", index: true
      t.text :smooch_request_type, null: true
      t.text :smooch_resource_id, null: true
      t.text :smooch_message_id, null: true
      t.text :smooch_conversation_id, null: true
      t.jsonb :smooch_data, null: false, default: {}
      t.references :associated, polymorphic: true, null: false
      t.references :team, null: true
      t.references :user
      t.timestamp :smooch_report_received, null: true
      t.timestamp :smooch_report_correction_sent_at, null: true
      t.timestamp :smooch_report_sent_at, null: true
      t.timestamps
    end
    add_index :tipline_requests, [:associated_type, :associated_id]
  end
end
