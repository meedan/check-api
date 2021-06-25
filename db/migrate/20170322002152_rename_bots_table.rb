class RenameBotsTable < ActiveRecord::Migration
  def change
    rename_table(:bots, :bot_bots) if ApplicationRecord.connection.table_exists?(:bots)
  end
end
