class CreateAnnotationOnPostgres < ActiveRecord::Migration[4.2]
  def change
    create_table :annotations, force: true do |t|
      t.string :annotation_type, null: false
      t.integer :version_index
      t.string :annotated_type
      t.integer :annotated_id
      t.string :context_type
      t.integer :context_id
      t.string :annotator_type
      t.integer :annotator_id
      t.text :entities
      t.text :data
      t.timestamps
    end

    add_index :annotations, :annotation_type
    add_index :annotations, [:annotated_type, :annotated_id]
    add_index :annotations, [:context_type, :context_id]
    add_index :annotations, [:annotator_type, :annotator_id]
  end
end
