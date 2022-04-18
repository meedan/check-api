class AddMoreRelationshipMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :relationships, :original_weight, :float, default: 0
    add_column :relationships, :original_details, :jsonb, default: '{}'
    add_column :relationships, :original_relationship_type, :string
    add_column :relationships, :original_model, :string
    add_column :relationships, :original_source_id, :integer
    add_column :relationships, :original_source_field, :string
  end
end
