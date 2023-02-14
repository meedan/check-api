class CreateDynamicAnnotationAnnotationTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :dynamic_annotation_annotation_types, id: false do |t|
      t.string :annotation_type, primary_key: true, null: false
      t.string :label, null: false
      t.text :description
      t.boolean :singleton, default: true
      t.jsonb :json_schema
      t.timestamps null: false
    end
    add_index :dynamic_annotation_annotation_types, :json_schema, using: :gin
  end
end
