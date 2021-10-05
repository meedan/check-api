class AddInitialStatusToMedia < ActiveRecord::Migration[4.2]
  def change
    unless defined?(Status).nil?
      ProjectMedia.all.each do |pm|
        pm.set_initial_media_status
      end
    end
  end
end
