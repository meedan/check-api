class AddIndexToCreatedAtForArticles < ActiveRecord::Migration[6.1]
  def change
    execute "CREATE INDEX fact_check_created_at_day ON fact_checks (date_trunc('day', created_at))"
    add_index :fact_checks, :created_at
    execute "CREATE INDEX explainer_created_at_day ON explainers (date_trunc('day', created_at))"
    add_index :explainers, :created_at
  end
end
