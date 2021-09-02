namespace :check do
  namespace :migrate do
    task remove_duplicate_relationships: :environment do
      started = Time.now.to_i
      ids = []
      Relationship.select('MAX(id) as id_max, MIN(id) as id_min, source_id, target_id')
      .where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml)
      .group('source_id, target_id').having("count(source_id) > ?", 1).each do |relationship|
        print '.'
        ids << relationship.id_max
        ids << relationship.id_min
      end
      Relationship.where(id: ids).where('relationship_type = ?', Relationship.suggested_type.to_yaml).destroy_all
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
