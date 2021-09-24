class CreateDynamicAnnotationFieldTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :dynamic_annotation_field_types, id: false do |t|
      t.string :field_type, primary_key: true, null: false
      t.string :label, null: false
      t.text :description

      t.timestamps null: false
    end
  end
end
