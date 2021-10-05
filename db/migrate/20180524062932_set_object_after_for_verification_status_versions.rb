class SetObjectAfterForVerificationStatusVersions < ActiveRecord::Migration[4.2]
  def change
    PaperTrail::Version.where(event_type: 'update_dynamicannotationfield').find_each do |version|
      item = DynamicAnnotation::Field.where(id: version.item_id).last
      if !item.nil? && version.item_type == 'DynamicAnnotation::Field' && item.field_name == 'verification_status_status'
        object_after = item.as_json.merge(JSON.parse(version.object_after)).to_json
        version.skip_notifications = true
        version.skip_check_ability = true
        version.skip_clear_cache = true
        version.update_attributes({ object_after: object_after })
      end
    end
  end
end
