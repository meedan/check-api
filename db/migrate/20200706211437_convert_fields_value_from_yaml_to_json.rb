class ConvertFieldsValueFromYamlToJson < ActiveRecord::Migration[4.2]
  BATCH_SIZE = 10000

  class NewDynamicAnnotationField < DynamicAnnotation::Field
    self.table_name = 'new_dynamic_annotation_fields'
  end
  
  def change
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    # Create new table without any index, in order to be faster

    puts "[#{Time.now}] Creating new table..."
    drop_table('new_dynamic_annotation_fields') if table_exists?('new_dynamic_annotation_fields')
    create_table :new_dynamic_annotation_fields do |t|
      t.integer :annotation_id, null: false, foreign_key: true
      t.string :field_name, null: false, foreign_key: true
      t.string :annotation_type, null: false, foreign_key: true
      t.string :field_type, null: false, foreign_key: true
      t.text :value, null: false
      t.jsonb :value_json, default: '{}'
      t.timestamps null: false
    end

    # Insert data into new table

    puts "[#{Time.now}] Converting fields..."
    n = DynamicAnnotation::Field.count
    i = 0
    result = execute("SELECT * FROM dynamic_annotation_fields ORDER BY id ASC LIMIT #{BATCH_SIZE} OFFSET #{BATCH_SIZE * i}").to_a
    while !result.empty? do
      print '.'
      result.each do |field|
        value = YAML.load(field['value'])
        field['value'] = value
        field['value_json'] = begin JSON.parse(field['value_json']) rescue field['value_json'] end
      end
      NewDynamicAnnotationField.import result, validate: false, recursive: false, timestamps: false
      i += 1
      result = execute("SELECT * FROM dynamic_annotation_fields ORDER BY id ASC LIMIT #{BATCH_SIZE} OFFSET #{BATCH_SIZE * i}").to_a
    end

    # Replace old table by new table

    puts "[#{Time.now}] Replacing old table by new table..."
    ['DROP TABLE dynamic_annotation_fields', 'ALTER TABLE new_dynamic_annotation_fields RENAME TO dynamic_annotation_fields'].each { |sql| execute(sql) }
    add_index :dynamic_annotation_fields, :field_name
    add_index :dynamic_annotation_fields, :annotation_id
    add_index :dynamic_annotation_fields, :field_type
    add_index :dynamic_annotation_fields, :value, name: 'index_status', where: "field_name = 'verification_status_status'"
    add_index :dynamic_annotation_fields, :value_json, using: :gin
    max = DynamicAnnotation::Field.maximum(:id)
    execute "ALTER SEQUENCE new_dynamic_annotation_fields_id_seq RESTART WITH #{max + 1}"
    puts "[#{Time.now}] Done!"

    ActiveRecord::Base.logger = old_logger
  end
end
