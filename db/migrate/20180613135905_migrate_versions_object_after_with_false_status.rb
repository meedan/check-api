class MigrateVersionsObjectAfterWithFalseStatus < ActiveRecord::Migration
  def change
  	PaperTrail::Version.where("object_changes ILIKE ?", '%"value":[%,"false"]%').find_each do |v|
  		object_after = JSON.parse(v.object_after)
  		object_after["value"] = "false"
  		v.object_after = object_after.to_json
  		v.save!
  	end
  end
end
