class CreateDynamicAnnotationFieldInstances < ActiveRecord::Migration[4.2]
  def change
    create_table :dynamic_annotation_field_instances, id: false do |t|
      t.string :name, primary_key: true, null: false
      t.string :field_type, foreign_key: true, null: false
      t.string :annotation_type, foreign_key: true, null: false
      t.string :label, null: false
      t.text :description
      t.boolean :optional, default: true
      t.text :settings
      t.string :default_value

      t.timestamps null: false
    end
  end
end
