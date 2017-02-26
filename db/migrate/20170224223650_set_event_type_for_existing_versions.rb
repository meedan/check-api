class SetEventTypeForExistingVersions < ActiveRecord::Migration
  def change
    PaperTrail::Version.find_each do |version|
      version.set_event_type
      version.save!
    end
  end
end
