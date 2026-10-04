class AddTokenToCheckDataExports < ActiveRecord::Migration[6.1]
  def change
    add_column :check_data_exports, :token, :string
    add_column :check_data_exports, :use_count, :integer, null: false, default: 0
  end
end
