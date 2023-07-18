class AddSignatureToFactChecks < ActiveRecord::Migration[6.1]
  def change
    add_column :fact_checks, :signature, :string
    add_index :fact_checks, :signature, unique: true
  end
end
