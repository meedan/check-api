class AddUniqIndexForClaimDescriptionAndFactCheck < ActiveRecord::Migration[5.2]
  def change
    remove_index :claim_descriptions, name: "index_claim_descriptions_on_project_media_id"
    remove_index :fact_checks, name: "index_fact_checks_on_claim_description_id"
    # remove duplicate keys
    # FactCheck table
    while true
      ids = FactCheck.select('MIN(id) as fc_id, claim_description_id')
      .group('claim_description_id').having("count(claim_description_id) > ?", 1)
      .map(&:fc_id)
      break if ids.blank?
      FactCheck.where(id: ids).destroy_all
    end
    # ClaimDescription table
    while true
      ids = ClaimDescription.select('MIN(id) as cd_id, project_media_id')
      .group('project_media_id').having("count(project_media_id) > ?", 1)
      .map(&:cd_id)
      break if ids.blank?
      ClaimDescription.where(id: ids).destroy_all
    end
    # add unique index
    add_index :claim_descriptions, :project_media_id, unique: true
    add_index :fact_checks, :claim_description_id, unique: true
  end
end
