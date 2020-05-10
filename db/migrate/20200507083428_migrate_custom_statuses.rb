class MigrateCustomStatuses < ActiveRecord::Migration
  def change
  	Rails.cache.write('check:migrate:migrate_custom_statuses', Time.now)
  end
end
