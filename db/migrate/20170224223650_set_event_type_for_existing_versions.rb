class SetEventTypeForExistingVersions < ActiveRecord::Migration[4.2]
  def change
    PaperTrail::Version.find_each do |version|
      version.set_event_type
      version.save!
    end
  end
end
