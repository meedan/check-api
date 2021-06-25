class AddLastActiveAtToUsers < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:add_last_active_at_to_users:last_id', User.last&.id || 0)
    add_column :users, :last_active_at, :datetime
  end
end
