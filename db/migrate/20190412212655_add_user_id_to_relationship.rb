class AddUserIdToRelationship < ActiveRecord::Migration[4.2]
  def change
    add_column(:relationships, :user_id, :integer) unless column_exists?(:relationships, :user_id)

    # Remember the last relationship paper trail id we need to work on since once this code is deployed,
    # all subsequent relationships will have the proper user id as per above.
    Rails.cache.write('check:migrate:add_user_id_to_relationship:last_id', PaperTrail::Version.where(item_type: 'Relationship')&.last&.id || 0)
  end
end
