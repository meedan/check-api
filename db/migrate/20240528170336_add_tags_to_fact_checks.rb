class AddTagsToFactChecks < ActiveRecord::Migration[6.1]
  def change
    add_column :fact_checks, :tags, :string, array: true, default: []
    add_index :fact_checks, :tags, using: 'gin'
  end
end
