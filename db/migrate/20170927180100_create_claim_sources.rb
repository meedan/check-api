class CreateClaimSources < ActiveRecord::Migration
  def change
    create_table :claim_sources do |t|
      t.belongs_to :media, index: true
      t.belongs_to :source, index: true

      t.timestamps null: false
    end
  end
end
