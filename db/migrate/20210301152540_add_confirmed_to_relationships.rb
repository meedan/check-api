class AddConfirmedToRelationships < ActiveRecord::Migration
  def change
    add_column :relationships, :confirmed_by, :integer # User ID
    add_column :relationships, :confirmed_at, :datetime
  end
end
