class AddStateColumnToTiplineMessage < ActiveRecord::Migration[6.1]
  def change
    add_column :tipline_messages, :state, :string
    remove_index :tipline_messages, name: "index_tipline_messages_on_external_id"
    add_index :tipline_messages, :external_id
    # updated state for existing records
    TiplineMessage.where(direction: "incoming").update_all(state: 'received')
    TiplineMessage.where(direction: "outgoing").update_all(state: 'delivered')
  end
end
