class AddInitialStatusToMedia < ActiveRecord::Migration
  def change
    ProjectMedia.all.each do |pm|
      pm.set_initial_media_status
    end
  end
end
