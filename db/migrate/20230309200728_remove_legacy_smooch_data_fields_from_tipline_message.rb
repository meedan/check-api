class RemoveLegacySmoochDataFieldsFromTiplineMessage < ActiveRecord::Migration[5.2]
  def change
    # Delete all TiplineMessages created by trying to migrate past data. This should not
    # have an effect in deployed environments, but will help keep local clean
    TiplineMessage.where(imported_from_legacy_smooch_data: false).delete_all

    remove_column :tipline_messages, :imported_from_legacy_smooch_data, :boolean, default: :false
    remove_column :tipline_messages, :legacy_smooch_data, :jsonb, default: {}
    remove_column :tipline_messages, :legacy_smooch_message_text, :string
  end
end
