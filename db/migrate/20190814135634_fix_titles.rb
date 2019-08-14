class FixTitles < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:fix_titles:last_id', ProjectMedia.last&.id || 0)
  end
end
