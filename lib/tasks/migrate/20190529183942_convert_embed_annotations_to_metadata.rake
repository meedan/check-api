namespace :check do
  namespace :migrate do
    task convert_embed_annotations_to_metadata: :environment do
      RequestStore.store[:skip_notifications] = true
      total = Annotation.where(annotation_type: 'embed').count
      puts "[#{Time.now}] Starting to convert #{total} embed annotations into metadata annotations..."

      LIMIT = 1000

      sum = 0
      n = Annotation.where(annotation_type: 'embed').limit(LIMIT).count
      nv = PaperTrail::Version.where(item_type: 'Embed').order('id ASC').limit(LIMIT).count
      while n > 0 || nv > 0
        puts "[#{Time.now}] Starting to convert #{n} embed annotations into metadata annotations, #{sum} converted, #{total - sum} remaining..."
        sum += n
        i = 0
        id = 0
        fields = []
        Annotation.where(annotation_type: 'embed').limit(LIMIT).order('id ASC').each do |a|
          i += 1
          print "#{i}/#{n}\r"
          $stdout.flush

          data = a.data || {}
          data = data.with_indifferent_access
          embed = data['embed'] || {}
          embed = begin JSON.parse(embed) rescue {} end
          data = data.merge(embed)
          data.delete('embed')
          json = data.to_json.delete("\u0000").gsub("\\u0000", '')

          field = DynamicAnnotation::Field.new({
            annotation_id: a.id,
            field_name: 'metadata_value',
            annotation_type: 'metadata',
            field_type: 'json',
            value: json,
            value_json: JSON.parse(json),
            created_at: a.created_at,
            updated_at: a.updated_at,
          })

          fields << field

          id = a.id
        end

        puts "[#{Time.now}] Bulk-importing #{fields.size} fields..."
        DynamicAnnotation::Field.import(fields, recursive: false, validate: false)

        puts "[#{Time.now}] Updating #{n} annotations..."
        Annotation.where(annotation_type: 'embed').where("id <= #{id}").update_all(annotation_type: 'metadata', data: {})

        puts "[#{Time.now}] Updating #{nv} versions..."
        vid = PaperTrail::Version.where(item_type: 'Embed').order('id ASC').limit(LIMIT).last&.id&.to_i
        PaperTrail::Version.where(item_type: 'Embed').where("id <= #{vid}").update_all(item_type: 'Annotation')

        n = Annotation.where(annotation_type: 'embed').limit(LIMIT).count
        nv = PaperTrail::Version.where(item_type: 'Embed').order('id ASC').limit(LIMIT).count
      end

      puts "[#{Time.now}] Done! Verifying (the queries below should return zero results)..."
      puts "[#{Time.now}] Embed annotations: #{Annotation.where(annotation_type: 'embed').count} Embed versions: #{PaperTrail::Version.where(item_type: 'Embed').count}"
      RequestStore.store[:skip_notifications] = false
    end
  end
end
