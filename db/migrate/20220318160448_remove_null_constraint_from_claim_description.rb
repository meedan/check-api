class RemoveNullConstraintFromClaimDescription < ActiveRecord::Migration[5.2]
  def change
    change_column_null :claim_descriptions, :description, true
  end
end
