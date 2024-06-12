class AddUuidToMedias < ActiveRecord::Migration[6.1]
  def change
    add_column :medias, :uuid, :integer, null: false, default: 0
  end
end
