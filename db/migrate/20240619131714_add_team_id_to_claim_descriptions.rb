class AddTeamIdToClaimDescriptions < ActiveRecord::Migration[6.1]
  def change
    add_reference :claim_descriptions, :team, index: true
    change_column_null :claim_descriptions, :project_media_id, true
  end
end
