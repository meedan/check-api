class MoveFilesToS3 < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:s3', Time.now.to_i.to_s)
  end
end
