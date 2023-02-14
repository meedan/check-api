class CreateAnnotationOnPostgres < ActiveRecord::Migration[4.2]
  def change
    create_table :annotations, force: true do |t|
      t.string :annotation_type, null: false
      t.integer :version_index
      t.string :annotated_type
      t.integer :annotated_id
      t.string :annotator_type
      t.integer :annotator_id
      t.text :entities
      t.text :data
      t.string :file
      t.integer :lock_version, default: 0, null: false
      t.boolean :locked, default: false
      t.text :attribution
      t.text :fragment
      t.timestamps
    end

    add_index :annotations, :annotation_type
    add_index :annotations, [:annotated_type, :annotated_id]
    add_index :annotations, :annotation_type, name: 'index_annotation_type_order', order: { name: :varchar_pattern_ops }
  end
end
