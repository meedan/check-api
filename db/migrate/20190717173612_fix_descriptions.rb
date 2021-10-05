class FixDescriptions < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:fix_descriptions:last_id', ProjectMedia.last&.id || 0)
  end
end
