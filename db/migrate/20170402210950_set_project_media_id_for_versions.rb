class SetProjectMediaIdForVersions < ActiveRecord::Migration
  def change
    PaperTrail::Version.reset_column_information
    PaperTrail::Version.find_each do |version|
      version.set_project_media_id
      version.save!
    end
  end
end
