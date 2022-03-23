class AddContextToClaimDescriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :claim_descriptions, :context, :text
  end
end
