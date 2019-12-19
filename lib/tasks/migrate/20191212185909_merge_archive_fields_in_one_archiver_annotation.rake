namespace :check do
  namespace :migrate do
    task merge_archive_fields_in_one_archiver_annotation: :environment do
      RequestStore.store[:skip_notifications] = true
      archiver_annotation_types = Bot::Keep.archiver_annotation_types 
      total = Annotation.where(annotation_type: archiver_annotation_types).count
      total_fields = DynamicAnnotation::Field.where(annotation_type: archiver_annotation_types).count
      puts "[#{Time.now}] Starting to convert #{total} specific archive annotations into archiver annotations and update #{total_fields} annotation fields..."

      LIMIT = 1000

      sum = 0
      n = Annotation.where(annotation_type: archiver_annotation_types).limit(LIMIT).count
      nf = DynamicAnnotation::Field.where(annotation_type: archiver_annotation_types).limit(LIMIT).count
      while n > 0 || nf > 0
        puts "[#{Time.now}] Starting to convert #{n} specific archive annotations into archiver annotations, #{sum} converted, #{total - sum} remaining..."
        sum += n
        i = 0
        ids = []
        Annotation.where(annotation_type: archiver_annotation_types).limit(LIMIT).order('id ASC').each do |a|
          i += 1
          print "#{i}/#{n}\r"
          $stdout.flush
          archiver = Annotation.where(annotation_type: 'archiver', annotated_type: a.annotated_type, annotated_id: a.annotated_id).last
          if archiver.nil?
            a.update_columns(annotation_type: 'archiver')
          else
            ids << a.id
            DynamicAnnotation::Field.where(annotation_id: a.id).update_all(annotation_id: archiver.id)
          end
        end

        puts "[#{Time.now}] Updating #{nf} annotation fields..."
        fid = DynamicAnnotation::Field.where(annotation_type: archiver_annotation_types).order('id ASC').limit(LIMIT).last&.id&.to_i
        DynamicAnnotation::Field.where(annotation_type: archiver_annotation_types).where("id <= #{fid}").update_all(annotation_type: 'archiver')

        puts "[#{Time.now}] Deleting #{ids.size} specific annotations..."
        Annotation.delete_all(id: ids)

        n = Annotation.where(annotation_type: archiver_annotation_types).limit(LIMIT).count
        nf = DynamicAnnotation::Field.where(annotation_type: archiver_annotation_types).limit(LIMIT).count
      end

      total_archivers = Annotation.where(annotation_type: 'archiver').count
      total_archivers_fields = DynamicAnnotation::Field.where(annotation_type: 'archiver').count
      puts "[#{Time.now}] #{total} specific archive annotations converted to #{total_archivers} archiver annotations and #{total_archivers_fields} annotation fields updated."

      puts "[#{Time.now}] Done! Verifying (the queries below should return zero results)..."
      puts "[#{Time.now}] Specific archive annotations: #{Annotation.where(annotation_type: archiver_annotation_types).count}"
      puts "[#{Time.now}] Fields with specific annotation type #{DynamicAnnotation::Field.where(annotation_type: archiver_annotation_types).count}"

      RequestStore.store[:skip_notifications] = false
    end
  end
end
