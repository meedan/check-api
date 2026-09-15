class ChangeColumnNullInCheckDataExports < ActiveRecord::Migration[6.1]
  def change
    change_column_null :check_data_exports, :download_url, true
    change_column_null :check_data_exports, :expired_at, true
    add_column :check_data_exports, :status, :integer, null: false, default: 0
    add_index  :check_data_exports, :status
  end
end
