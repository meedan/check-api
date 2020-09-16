namespace :check do
  namespace :migrate do
    task convert_analysis: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      errors = 0
      SIZE = 5000

      # Delete existing fields

      n = DynamicAnnotation::Field.where(annotation_type: 'verification_status', field_name: ['title', 'content']).count
      puts "[#{Time.now}] Deleting #{n} existing fields..."
      DynamicAnnotation::Field.where(annotation_type: 'verification_status', field_name: ['title', 'content']).delete_all

      # ProjectMedia "metadata" annotations

      n = DynamicAnnotation::Field.joins(:annotation).where(field_name: 'metadata_value', 'annotations.annotation_type' => 'metadata', 'annotations.annotated_type' => 'ProjectMedia').count
      puts "[#{Time.now}] Converting and deleting #{n} project media metadata annotations and fields..."
      i = 0
      q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
      result = ActiveRecord::Base.connection.execute(q).to_a
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
            end
          end
        end
        DynamicAnnotation::Field.import new_fields, validate: false, recursive: false, timestamps: false
        i += 1
        puts "[#{Time.now}] Imported #{SIZE * i}/#{n} project media metadata fields..."
        q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
        result = ActiveRecord::Base.connection.execute(q).to_a
      end

      i = 0
      q = "SELECT f.id, f.annotation_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE}"
      result = ActiveRecord::Base.connection.execute(q).to_a
      while !result.empty? do
        annotation_ids = []
        field_ids = []
        result.each do |field|
          annotation_ids << field['annotation_id']
          field_ids << field['id']
        end
        Annotation.where(id: annotation_ids).delete_all
        DynamicAnnotation::Field.where(id: field_ids).delete_all
        i += 1
        puts "[#{Time.now}] Deleted #{SIZE * i}/#{n} project media metadata annotations and fields..."
        q = "SELECT f.id, f.annotation_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'metadata_value' AND a.annotation_type = 'metadata' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE}"
        result = ActiveRecord::Base.connection.execute(q).to_a
      end

      # ProjectMedia "analysis" annotations

      n = DynamicAnnotation::Field.joins(:annotation).where(field_name: 'analysis_text', 'annotations.annotation_type' => 'analysis', 'annotations.annotated_type' => 'ProjectMedia').count
      puts "[#{Time.now}] Converting and deleting #{n} project media analysis annotations and fields..."
      i = 0
      q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'analysis_text' AND a.annotation_type = 'analysis' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
      result = ActiveRecord::Base.connection.execute(q).to_a
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
            end
          end
        end
        DynamicAnnotation::Field.import new_fields, validate: false, recursive: false, timestamps: false
        i += 1
        puts "[#{Time.now}] Imported #{SIZE * i}/#{n} analysis fields..."
        q = "SELECT f.*, a.annotated_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'analysis_text' AND a.annotation_type = 'analysis' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE} OFFSET #{SIZE * i}"
        result = ActiveRecord::Base.connection.execute(q).to_a
      end

      i = 0
      q = "SELECT f.id, f.annotation_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'analysis_text' AND a.annotation_type = 'analysis' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE}"
      result = ActiveRecord::Base.connection.execute(q).to_a
      while !result.empty? do
        annotation_ids = []
        field_ids = []
        result.each do |field|
          annotation_ids << field['annotation_id']
          field_ids << field['id']
        end
        Annotation.where(id: annotation_ids).delete_all
        DynamicAnnotation::Field.where(id: field_ids).delete_all
        i += 1
        puts "[#{Time.now}] Deleted #{SIZE * i}/#{n} analysis annotations and fields..."
        q = "SELECT f.id, f.annotation_id FROM dynamic_annotation_fields f INNER JOIN annotations a ON a.id = f.annotation_id WHERE f.field_name = 'analysis_text' AND a.annotation_type = 'analysis' AND a.annotated_type = 'ProjectMedia' ORDER BY f.id ASC LIMIT #{SIZE}"
        result = ActiveRecord::Base.connection.execute(q).to_a
      end

      DynamicAnnotation::AnnotationType.where(annotation_type: 'analysis').destroy_all
      DynamicAnnotation::FieldInstance.where(name: 'analysis_text').destroy_all

      puts "[#{Time.now}] Done! Total errors: #{errors.size}. Please sanity-check the values below:"
      puts "- #{Annotation.where(annotation_type: 'analysis').count} analysis annotations"
      puts "- #{DynamicAnnotation::Field.where(field_name: 'analysis_text').count} analysis fields"
      puts "- #{Annotation.where(annotation_type: 'metadata', annotated_type: 'ProjectMedia').count} project media metadata annotations"
      puts "- #{DynamicAnnotation::Field.joins(:annotation).where(field_name: 'metadata_value', 'annotations.annotated_type' => 'ProjectMedia').count} project media metadata fields"
      puts "- #{DynamicAnnotation::Field.joins(:annotation).where(field_name: 'title', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotation_type' => 'verification_status').count} verification status title fields"
      puts "- #{DynamicAnnotation::Field.joins(:annotation).where(field_name: 'content', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotation_type' => 'verification_status').count} verification status content fields"

      ActiveRecord::Base.logger = old_logger
    end
  end
end
