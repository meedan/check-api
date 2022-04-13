# bundle exec rake check:data:similarity
def write_similarity_relationships_to_disk(query, filename)
  puts "Extracting data for accepted suggestions to #{filename}..."
  f = File.open(filename, "w")
  i = 0
  query.find_each do |r|
    i += 1
    puts("Relationship #{i}")
    f.write({
      source_team_slug: (r.source.team.slug rescue nil),
      model: r.model,
      weight: r.weight,
      source_id: r.source_id,
      source_field: r.source_field,
      source_media_type: (r.source.media.type rescue nil),
      target_id: r.target_id,
      target_field: r.target_field,
      target_media_type: (r.target.media.type rescue nil),
      details: r.details,
      created_at: r.created_at,
      source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.source.send(f) rescue nil)]}],
      target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.target.send(f) rescue nil)]}],
    }.to_json+"\n")
  end
  f.close
end

def write_archived_similarity_relationships_to_disk(object_change, filename)
  puts "Extracting data for accepted suggestions to #{filename}..."
  f = File.open(filename, "w")
  tids = Team.all.map(&:id)
  tids.each_with_index do |tid, i|
    j = 0
    Version.from_partition(tid).where(item_type: 'Relationship', event: 'destroy').where('object_changes LIKE ?', object_change).find_each do |v|
      j += 1
      puts "Team #{i+1} / #{tids.size}, version #{j}"
      r = JSON.parse(v.object)
      source = ProjectMedia.find_by_id(r['source_id'])
      target = ProjectMedia.find_by_id(r['target_id'])
      next if source.nil? || target.nil?
      f.write({
        source_team_slug: (source.team.slug rescue nil),
        model: r["model"],
        weight: r["weight"],
        source_id: source.id,
        source_field: r["source_field"],
        source_media_type: (source.media.type rescue nil),
        target_id: target.id,
        target_field: r["target_field"],
        target_media_type: (target.media.type rescue nil),
        details: r["details"],
        created_at: r["created_at"],
        source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (source.send(f) rescue nil)]}],
        target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (target.send(f) rescue nil)]}],
      }.to_json+"\n")
    end
  end
  f.close
end

namespace :check do
  namespace :data do
    desc 'Extract similarity data into CSV files.'
    task similarity: :environment do |_t, _params|
      # Accepted suggestions
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(user: BotUser.alegre_user).where('confirmed_by IS NOT NULL'),
        "/tmp/accepted.json"
      )

      # Confirmed suggestions
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(user: BotUser.alegre_user).where('confirmed_by IS NULL'),
        "/tmp/confirmed.json"
      )

      # Rejected suggestions
      write_archived_similarity_relationships_to_disk(
        '%suggested_sibling%',
        "/tmp/rejected.json"
      )


      # Manually created matches
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where.not(user: BotUser.alegre_user),
        "/tmp/manual.json"
      )

      # Manually detached matches
      write_archived_similarity_relationships_to_disk(
        "%confirmed_sibling%user_id\":[#{BotUser.alegre_user.id}%",
        "/tmp/detached.json"
      )

      # Suggestions
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml),
        "/tmp/suggestions.json"
      )
    end
  end
end
