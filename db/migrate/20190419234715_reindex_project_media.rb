class ReindexProjectMedia < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:reindex_project_media:progress', nil)
  end
end
