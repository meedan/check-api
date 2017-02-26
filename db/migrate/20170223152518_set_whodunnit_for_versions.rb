class SetWhodunnitForVersions < ActiveRecord::Migration
  def change
    add_column(:versions, :object_after, :text) unless PaperTrail::Version.column_names.include?('object_after')

    PaperTrail::Version.all.each do |version|
      print "Changing version #{version.id}... "

      if version.object_after.blank?
        version.object_after = version.apply_changes
      end

      if version.whodunnit.blank?
        object = JSON.parse(version.object_after)
        author = object['annotator_id'] || object['user_id']
        version.whodunnit = author.to_s
      end

      version.save!
      
      puts "Saved version #{version.id}"
    end
  end
end
