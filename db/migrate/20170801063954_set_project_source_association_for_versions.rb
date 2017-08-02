class SetProjectSourceAssociationForVersions < ActiveRecord::Migration
  def change
    PaperTrail::Version.where(associated_id: nil).find_each do |version|
      version.set_project_association
      version.save!
    end
  end
end
