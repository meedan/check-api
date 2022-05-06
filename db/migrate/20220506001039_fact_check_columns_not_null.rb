class FactCheckColumnsNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :fact_checks, :title, true
    change_column_null :fact_checks, :summary, true
  end
end
