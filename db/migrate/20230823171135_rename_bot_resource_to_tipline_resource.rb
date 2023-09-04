class RenameBotResourceToTiplineResource < ActiveRecord::Migration[6.1]
  def change
    rename_table :bot_resources, :tipline_resources
  end
end
