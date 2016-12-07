class MigrateProjectMediaFromPgToEs < ActiveRecord::Migration
  def change
    MediaSearch.delete_index
    MediaSearch.create_index
    ProjectMedia.all.each do |pm|
      pm.add_elasticseach_data unless pm.project.nil?
    end
  end
end
