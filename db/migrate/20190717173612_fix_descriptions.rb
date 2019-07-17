class FixDescriptions < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:fix_descriptions:last_id', ProjectMedia.last&.id || 0)
  end
end
