class MigrateProjectMediaFromPgToEs < ActiveRecord::Migration
  def change
    ProjectMedia.all.each do |pm|
      pm.add_elasticseach_data
    end
  end
end
