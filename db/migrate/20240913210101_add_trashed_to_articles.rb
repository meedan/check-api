class AddTrashedToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :fact_checks, :trashed, :boolean, default: false, index: true
    add_column :explainers, :trashed, :boolean, default: false, index: true
  end
end
