class AddConfirmedToRelationships < ActiveRecord::Migration[4.2]
  def change
    add_column :relationships, :confirmed_by, :integer # User ID
    add_column :relationships, :confirmed_at, :datetime
  end
end
