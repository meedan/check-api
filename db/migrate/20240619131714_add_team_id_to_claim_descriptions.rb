class AddTeamIdToClaimDescriptions < ActiveRecord::Migration[6.1]
  def change
    add_reference :claim_descriptions, :team, index: true
  end
end
