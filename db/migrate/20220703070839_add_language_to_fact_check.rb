class AddLanguageToFactCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :fact_checks, :language, :string, null: false, default: ""
    add_index :fact_checks, :language
  end
end
