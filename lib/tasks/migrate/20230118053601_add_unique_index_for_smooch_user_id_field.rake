namespace :check do
  namespace :migrate do
    task add_unique_index_for_smooch_user_id_field: :environment do
      started = Time.now.to_i
      i = 0
      loop do
        i = i + 1
        puts "Do a loop [#{i}] to collect duplicate fields and delete them ....\n"
        ids = DynamicAnnotation::Field.select('value')
        .where(annotation_type: "smooch_user", field_name: 'smooch_user_id')
        .group('value').having('COUNT(id) > ?', 1).maximum('id')
        DynamicAnnotation::Field.where(id: ids.values).find_in_batches(:batch_size => 500) do |fields|
          print '.'
          deleted_ids = fields.map(&:id)
          DynamicAnnotation::Field.where(id: deleted_ids).delete_all
        end
        break if ids.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
