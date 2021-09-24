class MoveFilesToS3 < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:s3', Time.now.to_i.to_s)
  end
end
