class MigrateVersionsObjectAfterWithFalseStatus < ActiveRecord::Migration[4.2]
  def change
  	PaperTrail::Version.where("object_changes ILIKE ?", '%"value":[%,"false"]%').find_each do |v|
  		object_after = JSON.parse(v.object_after)
  		if object_after["field_name"] == 'verification_status_status'
  			object_after["value"] = "false"
  			v.object_after = object_after.to_json
  			v.save!
  		end
  	end
  end
end
