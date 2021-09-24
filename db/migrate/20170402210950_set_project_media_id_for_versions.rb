class SetProjectMediaIdForVersions < ActiveRecord::Migration[4.2]
  def change
    PaperTrail::Version.reset_column_information
    PaperTrail::Version.find_each do |version|
      version.set_project_media_id
      version.save!
    end
  end
end
