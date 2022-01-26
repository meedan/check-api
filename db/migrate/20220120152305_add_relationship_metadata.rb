class AddRelationshipMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :relationships, :source_field, :string, default: nil
    add_column :relationships, :target_field, :string, default: nil
    add_column :relationships, :model, :string, default: nil
    add_column :relationships, :details, :jsonb, default: '{}'
  end
end
