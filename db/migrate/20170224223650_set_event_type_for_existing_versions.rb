class SetEventTypeForExistingVersions < ActiveRecord::Migration
  def change
    PaperTrail::Version.find_each do |version|
      version.set_event_type
      version.save!
      puts "Saved version #{version.id}"
    end
  end
end
