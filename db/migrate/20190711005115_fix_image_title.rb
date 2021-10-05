class FixImageTitle < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:fix_image_title:last_id', ProjectMedia.last&.id || 0)
  end
end
