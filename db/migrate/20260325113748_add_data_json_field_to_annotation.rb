class AddDataJsonFieldToAnnotation < ActiveRecord::Migration[6.1]
  def change
    add_column :annotations, :data_json, :jsonb
    add_index :annotations, :data_json, using: :gin
    add_index :annotations, "(data_json ->> 'tag')", name: "index_annotations_on_data_json_tag", where: "annotation_type = 'tag'"
  end
end
