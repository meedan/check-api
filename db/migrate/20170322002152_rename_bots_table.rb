class RenameBotsTable < ActiveRecord::Migration[4.2]
  def change
    rename_table(:bots, :bot_bots) if ApplicationRecord.connection.table_exists?(:bots)
  end
end
