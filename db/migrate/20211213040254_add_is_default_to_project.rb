class AddIsDefaultToProject < ActiveRecord::Migration[5.2]
  def change
    unless ApplicationRecord.connection.column_exists?(:projects, :is_default)
      add_column :projects, :is_default, :boolean, default: false
      add_index :projects, :is_default
    end
  end
end
