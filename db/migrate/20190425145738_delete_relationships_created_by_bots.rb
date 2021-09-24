class DeleteRelationshipsCreatedByBots < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:delete_relationships_created_by_bots:progress', nil)
  end
end
