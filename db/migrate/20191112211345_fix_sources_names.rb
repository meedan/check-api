class FixSourcesNames < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:fix_sources_names:progress', nil)
  end
end
