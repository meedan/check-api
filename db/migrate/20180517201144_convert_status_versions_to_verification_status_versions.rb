class ConvertStatusVersionsToVerificationStatusVersions < ActiveRecord::Migration[4.2]
  def change
    i = 0
    PaperTrail::Version.where(item_type: 'Status').find_each do |version|
      item = Annotation.where(id: version.item_id).last
      next if item.nil?
      next if item.annotated.nil?

      i += 1

      if version.event == 'create'
        version.item_type = 'Dynamic'
        version.event_type = 'create_dynamic'
       
        object_changes = begin JSON.parse(version.object_changes) rescue {} end
        object_changes.except!('data')
        object_changes['annotation_type'][1] = 'verification_status'
        version.object_changes = object_changes.to_json

        object_after = begin JSON.parse(version.object_after) rescue {} end
        value = object_after.has_key?('data') ? object_after['data']['status'] : object_after['status']
        object_after.except!('data')
        object_after['annotation_type'] = 'verification_status'
        version.object_after = object_after.to_json

        version.skip_notifications = true
        version.skip_check_ability = true
        version.skip_clear_cache = true
        version.save!

        new_version = PaperTrail::Version.new
        new_version.item_type = 'DynamicAnnotation::Field'
        field = Dynamic.find(version.item_id).get_field('verification_status_status')
        new_version.item_id = field.id.to_s
        new_version.event = 'create'
        new_version.whodunnit = version.whodunnit
        new_version.object_changes = {
          field_name: [nil, 'verification_status_status'],
          value: [nil, value],
          annotation_id: [nil, version.item_id.to_i],
          annotation_type: [nil, 'verification_status'],
          field_type: [nil, 'select'],
          id: [nil, field.id]
        }.to_json
        new_version.event_type = 'create_dynamicannotationfield'
        new_version.object_after = {
          field_name: 'verification_status_status',
          value: value,
          annotation_id: version.item_id.to_i,
          annotation_type: 'verification_status',
          field_type: 'select',
          id: field.id
        }.to_json
        new_version.associated_id = version.associated_id
        new_version.associated_type = version.associated_type
        new_version.skip_notifications = true
        new_version.skip_check_ability = true
        new_version.skip_clear_cache = true
        new_version.save!
        new_version.update_attributes({ created_at: version.created_at })

      elsif version.event == 'update'
        version.item_type = 'Dynamic'
        version.event_type = 'update_dynamic'

        object = begin JSON.parse(version.object) rescue {} end
        object['data'] = nil
        object['annotation_type'] = 'verification_status'
        version.object = object.to_json
        
        should_create_version = false
        values = []
        object_changes = begin JSON.parse(version.object_changes) rescue {} end
        if object_changes.has_key?('data')
          should_create_version = true
          values = object_changes['data'].collect do |x|
            x.is_a?(Hash) ? x['status'] : YAML.load(x)['status']
          end
        end
        object_changes.except!('data')
        version.object_changes = object_changes.to_json

        object_after = begin JSON.parse(version.object_after) rescue {} end
        value = object_after['data']['status']
        object_after.except!('data')
        object_after['annotation_type'] = 'verification_status'
        version.object_after = object_after.to_json

        version.skip_notifications = true
        version.skip_check_ability = true
        version.skip_clear_cache = true
        version.save!

        if should_create_version
          new_version = PaperTrail::Version.new
          new_version.item_type = 'DynamicAnnotation::Field'
          field = Dynamic.find(version.item_id).get_field('verification_status_status')
          new_version.item_id = field.id.to_s
          new_version.event = 'update'
          new_version.whodunnit = version.whodunnit
          new_version.object_changes = { value: values }.to_json
          new_version.event_type = 'update_dynamicannotationfield'
          new_version.object_after = {
            field_name: 'verification_status_status',
            value: value,
            annotation_id: version.item_id.to_i,
            annotation_type: 'verification_status',
            field_type: 'select',
            id: field.id
          }.to_json
          new_version.associated_id = version.associated_id
          new_version.associated_type = version.associated_type
          new_version.skip_notifications = true
          new_version.skip_check_ability = true
          new_version.skip_clear_cache = true
          new_version.save!
          new_version.update_attributes({ created_at: version.created_at })
        end
      end
    end
  end
end
