class AddUniqIndexForClaimDescriptionAndFactCheck < ActiveRecord::Migration[5.2]
  def change
    remove_index :claim_descriptions, name: "index_claim_descriptions_on_project_media_id"
    remove_index :fact_checks, name: "index_fact_checks_on_claim_description_id"
    add_index :claim_descriptions, :project_media_id, unique: true
    add_index :fact_checks, :claim_description_id, unique: true
  end
end
