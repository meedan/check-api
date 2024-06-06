class AddFieldsToFactCheck < ActiveRecord::Migration[6.1]
  def change
    add_column :fact_checks, :publisher_id, :integer, null: true
    add_column :fact_checks, :report_status, :integer, null: true
    add_column :fact_checks, :rating, :string, null: true
    add_index :fact_checks, :publisher_id
    add_index :fact_checks, :report_status
    add_index :fact_checks, :rating
  end
end
