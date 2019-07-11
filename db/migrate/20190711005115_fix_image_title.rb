class FixImageTitle < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:fix_image_title:last_id', ProjectMedia.last&.id || 0)
  end
end
