class ConvertStatusToVerificationStatus < ActiveRecord::Migration[4.2]
  def change
    i = 0
    Annotation.where(annotation_type: 'status').find_each do |status|
      next if status.annotated.nil?
      i += 1

      id = status.id
      value = status.data['status']
      
      s = Dynamic.find(id)
      s.annotation_type = 'verification_status'
      s.data = {}
      s.skip_notifications = true
      s.skip_check_ability = true
      s.save(validate: false)

      f = DynamicAnnotation::Field.new
      f.skip_check_ability = true
      f.skip_notifications = true
      f.field_name = 'verification_status_status'
      f.field_type = 'select'
      f.created_at = s.created_at
      f.updated_at = s.updated_at
      f.value = value
      f.annotation_id = id
      f.annotation_type = 'verification_status'
      f.save(validate: false)
    end
  end
end
