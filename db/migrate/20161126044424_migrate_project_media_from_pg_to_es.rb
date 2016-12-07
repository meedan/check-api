class MigrateProjectMediaFromPgToEs < ActiveRecord::Migration
  def change
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    MediaSearch.delete_index
    MediaSearch.create_index
    ProjectMedia.all.each do |pm|
      pm.add_elasticsearch_data unless pm.project.nil?
    end
  end
end
