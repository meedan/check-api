class MigrateCustomStatuses < ActiveRecord::Migration[4.2]
  def change
  	Rails.cache.write('check:migrate:migrate_custom_statuses', Time.now)
  end
end
