class FixSourcesNames < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:fix_sources_names:progress', nil)
  end
end
