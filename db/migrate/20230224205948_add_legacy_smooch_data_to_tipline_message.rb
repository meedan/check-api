class AddLegacySmoochDataToTiplineMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :tipline_messages, :imported_from_legacy_smooch_data, :boolean, default: :false
    add_column :tipline_messages, :legacy_smooch_data, :jsonb, default: {}
    add_column :tipline_messages, :legacy_smooch_message_text, :string

    remove_index :tipline_messages, name: "index_tipline_message_uniqueness", column: [:team_id, :uid, :platform, :language, :sent_at, :direction]
  end
end
