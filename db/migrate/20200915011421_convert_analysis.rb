class ConvertAnalysis < ActiveRecord::Migration
  SIZE = 10000

  def change
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    errors = 0

    # ProjectMedia "metadata" annotations

    n = DynamicAnnotation::Field.joins(:annotation).where(field_name: 'metadata_value', 'annotations.annotation_type' => 'metadata', 'annotations.annotated_type' => 'ProjectMedia').count
    puts "[#{Time.now}] Converting and deleting #{n} project media metadata annotations and fields..."
    i = 0
    q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
    result = execute(q).to_a
    annotations_to_delete = []
    fields_to_delete = []
    while !result.empty? do
      new_fields = []
      result.each do |field|
        pm = ProjectMedia.find_by_id(field['annotated_id'].to_i)
        unless pm.nil?
          s = pm.last_status_obj
          unless s.nil?
            value = nil
            begin
              value = JSON.parse(YAML.load(field['value']))
            rescue
              begin
                value = JSON.parse(field['value'])
              rescue
                puts "[#{Time.now}] Could not convert field with ID #{field['id']}"
                errors += 1
              end
            end
            unless value.nil?
              field_data = {
                annotation_id: s.id,
                annotation_type: 'verification_status',
                field_type: 'text',
                created_at: field['created_at'],
                updated_at: field['updated_at'],
                value_json: {}
              }
              new_fields << field_data.clone.merge({ value: value['title'], field_name: 'title' }) unless value['title'].blank?
              new_fields << field_data.clone.merge({ value: value['description'], field_name: 'content' }) if !value['description'].blank? && !Annotation.where(annotation_type: 'analysis', annotated_type: 'ProjectMedia', annotated_id: pm.id).exists?
            end
            fields_to_delete << field['id'].to_i
            annotations_to_delete << field['annotation_id'].to_i
          end
        end
      end
      DynamicAnnotation::Field.import new_fields, validate: false, recursive: false, timestamps: false
      i += 1
      puts "[#{Time.now}] Importing #{SIZE * i}/#{n} project media metadata fields..."
      q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
      result = execute(q).to_a
    end
    i = 0
    fields_to_delete.each_slice(SIZE) do |slice|
      i += 1
      puts "[#{Time.now}] Deleting #{SIZE * i}/#{n} project media metadata fields..."
      DynamicAnnotation::Field.where(id: slice).delete_all
    end
    i = 0
    annotations_to_delete.each_slice(SIZE) do |slice|
      i += 1
      puts "[#{Time.now}] Deleting #{SIZE * i}/#{n} project media metadata annotations..."
      Annotation.where(id: slice).delete_all
    end

    # ProjectMedia "analysis" annotations

    n = DynamicAnnotation::Field.joins(:annotation).where(field_name: 'analysis_text', 'annotations.annotation_type' => 'analysis', 'annotations.annotated_type' => 'ProjectMedia').count
    puts "[#{Time.now}] Converting and deleting #{n} project media analysis annotations and fields..."
    i = 0
    q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'analysis_text' AND a.annotation_type = 'analysis' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
    result = execute(q).to_a
    annotations_to_delete = []
    fields_to_delete = []
    while !result.empty? do
      new_fields = []
      result.each do |field|
        pm = ProjectMedia.find_by_id(field['annotated_id'].to_i)
        unless pm.nil?
          s = pm.last_status_obj
          unless s.nil?
            value = begin YAML.load(field['value']) rescue field['value'] end
            field_data = {
              annotation_id: s.id,
              annotation_type: 'verification_status',
              field_type: 'text',
              created_at: field['created_at'],
              updated_at: field['updated_at'],
              value_json: {},
              field_name: 'content',
              value: value
            }
            new_fields << field_data unless value.blank?
            fields_to_delete << field['id'].to_i
            annotations_to_delete << field['annotation_id'].to_i
          end
        end
      end
      DynamicAnnotation::Field.import new_fields, validate: false, recursive: false, timestamps: false
      i += 1
      puts "[#{Time.now}] Importing #{SIZE * i}/#{n} analysis fields..."
      q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
      result = execute(q).to_a
    end
    i = 0
    fields_to_delete.each_slice(SIZE) do |slice|
      i += 1
      puts "[#{Time.now}] Deleting #{SIZE * i}/#{n} analysis fields..."
      DynamicAnnotation::Field.where(id: slice).delete_all
    end
    i = 0
    annotations_to_delete.each_slice(SIZE) do |slice|
      i += 1
      puts "[#{Time.now}] Deleting #{SIZE * i}/#{n} analysis annotations..."
      Annotation.where(id: slice).delete_all
    end

    DynamicAnnotation::AnnotationType.where(annotation_type: 'analysis').destroy_all
    DynamicAnnotation::FieldInstance.where(name: 'analysis_text').destroy_all

    puts "[#{Time.now}] Done! Total errors: #{errors.size}. Please sanity-check the values below:"
    puts "- #{Annotation.where(annotation_type: 'analysis').count} analysis annotations"
    puts "- #{DynamicAnnotation::Field.where(field_name: 'analysis_text').count} analysis fields"
    puts "- #{Annotation.where(annotation_type: 'metadata', annotated_type: 'ProjectMedia').count} project media metadata annotations"
    puts "- #{DynamicAnnotation::Field.joins(:annotation).where(field_name: 'metadata_value', 'annotations.annotated_type' => 'ProjectMedia').count} project media metadata fields"

    ActiveRecord::Base.logger = old_logger
  end
end
