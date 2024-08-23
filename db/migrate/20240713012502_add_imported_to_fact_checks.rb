class AddImportedToFactChecks < ActiveRecord::Migration[6.1]
  def change
    add_column :fact_checks, :imported, :boolean, default: false
    add_index :fact_checks, :imported
  end
end
