class AllowNullProjectMediasToClaims < ActiveRecord::Migration[6.1]
  def change
    change_column_null :claim_descriptions, :project_media_id, true
  end
end
