class FixIdenticalUploadedFile < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:fix_identical_uploaded_file:last_id', Media.last&.id || 0)
  end
end
