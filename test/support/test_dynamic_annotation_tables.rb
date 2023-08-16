require 'csv'

class TestDynamicAnnotationTables
  class << self
    CSV_DIRECTORY = "#{Rails.root}/test/data/".freeze

    MODEL_TO_OUTPUT_FILEMAPPING = {
      DynamicAnnotation::AnnotationType => File.join(CSV_DIRECTORY, "dynamic_annotation_annotation_types.csv").freeze,
      DynamicAnnotation::FieldType => File.join(CSV_DIRECTORY, "dynamic_annotation_field_types.csv").freeze,
      DynamicAnnotation::FieldInstance => File.join(CSV_DIRECTORY, "dynamic_annotation_field_instances.csv").freeze,
    }.freeze

    # Dump data related to required dynamic annotations. Intended for testing that touches GraphQL schema
    def dump!
      MODEL_TO_OUTPUT_FILEMAPPING.each do |klass, filepath|
        write_table_to_file(klass, filepath, %w[created_at updated_at])
      end
    end

    # Load data related to required dynamic annotations. Intended for testing that touches GraphQL schema
    def load!
      MODEL_TO_OUTPUT_FILEMAPPING.each do |klass, filepath|
        load_table_from_file(klass, filepath)
      end
    end

    private

    def write_table_to_file(klass, filepath, unwanted_keys)
      CSV.open(filepath, 'wb' ) do |writer|
        writer << (klass.attribute_names - unwanted_keys)
        klass.find_each do |obj|
          values = obj.attributes.reject{|attr_name, _val| unwanted_keys.include?(attr_name) }.values
          writer << values.map{|val| val.is_a?(Hash) ? val.to_json : val }
        end
      end
    end

    def load_table_from_file(klass, filepath)
      CSV.foreach(filepath, headers: true) do |row|
        obj = klass.new(row.to_h)
        if obj.valid?
          obj.save
        end
      end
    end
  end
end
