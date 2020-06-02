class RemoveProjectSourceAndClaimSource < ActiveRecord::Migration
  def change
    drop_table(:project_sources) if table_exists?(:project_sources)
    drop_table(:claim_sources) if table_exists?(:claim_sources)
    Rails.cache.write('check:migrate:remove_project_source_and_claim_source', Time.now)
  end
end
