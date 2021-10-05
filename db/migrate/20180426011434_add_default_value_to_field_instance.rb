class AddDefaultValueToFieldInstance < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :dynamic_annotation_field_instances, :default_value
      add_column :dynamic_annotation_field_instances, :default_value, :string
    end
    DynamicAnnotation::FieldInstance.reset_column_information
    {
      status: 'pending',
      note: '',
      approver: '{}'
    }.each do |name, value|
      fi = DynamicAnnotation::FieldInstance.where(name: "translation_status_#{name}").last
      fi.default_value = value
      fi.save!
    end
  end
end
