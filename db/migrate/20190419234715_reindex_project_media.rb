class ReindexProjectMedia < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:reindex_project_media:progress', nil)
  end
end
