class AllowNilArticleChannel < ActiveRecord::Migration[6.1]
  def change
    change_column_default :explainers, :channel, from: 1, to: nil
    change_column_default :fact_checks, :channel, from: 1, to: nil
  end
end
