namespace :check do
  namespace :migrate do
    task convert_metadata_published_at_to_string: :environment do
      last_id = Rails.cache.read('check:migrate:convert_metadata_published_at_to_string:last_id')
      raise "No last_id found in cache for check:convert_metadata_published_at_to_string! Aborting." if last_id.nil?

      t = Time.new(2019,05,31,19,05,23)
      filters = ["id < :id AND created_at > :last_migration AND field_name = :field_name", { id: last_id, last_migration: t, field_name: 'metadata_value'}]
      fields = DynamicAnnotation::Field.where(filters).where("value_json->>'published_at' IS NOT NULL").where.not("value_json->>'published_at' = ''")
      total = fields.size
      puts "[#{Time.now}] Verifying #{total} metadata fields created after the last migration..."

      i = 0; n = 0
      updated_fields = []
      fields.find_each do |f|
        if f.value_json['published_at'].is_a?(Numeric)
          value = JSON.parse(f.value)
          value['published_at'] = value['published_at'].zero? ? '' : Time.at(value['published_at'])
          f.value = value.to_json
          f.value_json = value
          updated_fields << f
          n += 1
        end
        i += 1
        print "#{i}/#{total}: #{n} fields to update\r"
        $stdout.flush
      end

      puts "[#{Time.now}] Bulk-updating #{n} fields..."
      DynamicAnnotation::Field.import(updated_fields, on_duplicate_key_update: [ :value, :value_json, :updated_at ], recursive: false, validate: false)

      Rails.cache.delete('check:migrate:convert_metadata_published_at_to_string:last_id')
    end
  end
end
