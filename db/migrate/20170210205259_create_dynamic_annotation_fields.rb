class CreateDynamicAnnotationFields < ActiveRecord::Migration[4.2]
  def change
    create_table :dynamic_annotation_fields do |t|
      t.integer :annotation_id, null: false, index: true, foreign_key: true
      t.string :field_name, null: false, index: true, foreign_key: true
      
      t.string :annotation_type, null: false, index: true, foreign_key: true # redundant
      t.string :field_type, null: false, index: true, foreign_key: true # redundant
      
      t.text :value, null: false

      t.timestamps null: false
    end
  end
end
