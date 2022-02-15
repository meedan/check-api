# bundle exec rake check:data:similarity

namespace :check do
  namespace :data do
    desc 'Extract similarity data into CSV files.'
    task similarity: :environment do |_t, _params|
      # Accepted suggestions
      puts 'Extracting data for accepted suggestions to /tmp/accepted.json...'
      f = File.open("/tmp/accepted.json", "w")
      i = 0
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(user: BotUser.alegre_user).where('confirmed_by IS NOT NULL').find_each do |r|
        i += 1
        puts("Relationship #{i}")
        f.write({
          source_team_slug: r.source.team.slug,
          model: r.model,
          weight: r.weight,
          source_id: r.source_id,
          source_field: r.source_field,
          source_media_type: r.source.media.type,
          target_id: r.target_id,
          target_field: r.target_field,
          target_media_type: r.target.media.type,
          details: r.details,
          created_at: r.created_at,
          source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.source.send(f) rescue nil)]}],
          target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.target.send(f) rescue nil)]}],
        }.to_json+"\n")
      end
      f.close

      # Rejected suggestions
      puts 'Extracting data for rejected suggestions to /tmp/rejected.json...'
      f = File.open("/tmp/rejected.json", "w")
      tids = Team.all.map(&:id)
      tids.each_with_index do |tid, i|
        j = 0
        Version.from_partition(tid).where(item_type: 'Relationship', event: 'destroy').where('object_changes LIKE ?', '%suggested_sibling%').find_each do |v|
          j += 1
          puts "Team #{i+1} / #{tids.size}, version #{j}"
          r = JSON.parse(v.object)
          source = ProjectMedia.find_by_id(r['source_id'])
          target = ProjectMedia.find_by_id(r['target_id'])
          next if source.nil? || target.nil?
          f.write({
            source_team_slug: source.team.slug,
            model: r["model"],
            weight: r["weight"],
            source_id: source.id,
            source_field: r["source_field"],
            source_media_type: source.media.type,
            target_id: target.id,
            target_field: r["target_field"],
            target_media_type: target.media.type,
            details: r["details"],
            created_at: r["created_at"],
            source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (source.send(f) rescue nil)]}],
            target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (target.send(f) rescue nil)]}],
          }.to_json+"\n")
        end
      end
      f.close

      # Manually created matches
      puts 'Extracting data for manual matches to /tmp/manual.json...'
      f = File.open("/tmp/manual.json", "w")
      i = 0
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where.not(user: BotUser.alegre_user).find_each do |r|
        i += 1
        puts("Relationship #{i}")
        f.write({
          source_team_slug: r.source.team.slug,
          model: r.model,
          weight: r.weight,
          source_id: r.source_id,
          source_field: r.source_field,
          source_media_type: r.source.media.type,
          target_id: r.target_id,
          target_field: r.target_field,
          target_media_type: r.target.media.type,
          details: r.details,
          created_at: r.created_at,
          source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.source.send(f) rescue nil)]}],
          target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.target.send(f) rescue nil)]}],
        }.to_json+"\n")
      end
      f.close

      # Manually detached matches
      puts 'Extracting data for detached matches to /tmp/detached.json...'
      f = File.open("/tmp/detached.json", "w")
      tids = Team.all.map(&:id)
      tids.each_with_index do |tid, i|
        j = 0
        Version.from_partition(tid).where(item_type: 'Relationship', event: 'destroy').where('object_changes LIKE ?', "%confirmed_sibling%user_id\":[#{BotUser.alegre_user.id}%").find_each do |v|
          j += 1
          puts "Team #{i+1} / #{tids.size}, version #{j}"
          r = JSON.parse(v.object)
          source = ProjectMedia.find_by_id(r['source_id'])
          target = ProjectMedia.find_by_id(r['target_id'])
          next if source.nil? || target.nil?
          f.write({
            source_team_slug: source.team.slug,
            model: r["model"],
            weight: r["weight"],
            source_id: source.id,
            source_field: r["source_field"],
            source_media_type: source.media.type,
            target_id: target.id,
            target_field: r["target_field"],
            target_media_type: target.media.type,
            details: r["details"],
            created_at: r["created_at"],
            source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (source.send(f) rescue nil)]}],
            target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (target.send(f) rescue nil)]}],
          }.to_json+"\n")
        end
      end
      f.close

      # Suggestions
      puts 'Extracting data for suggestions to /tmp/suggestions.json...'
      f = File.open("/tmp/suggestions.json", "w")
      i = 0
      Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml).find_each do |r|
        i += 1
        puts("Relationship #{i}")
        next if r.source.nil? || r.target.nil?
        f.write({
          source_team_slug: r.source.team.slug,
          model: r.model,
          weight: r.weight,
          source_id: r.source_id,
          source_field: r.source_field,
          source_media_type: r.source.media.type,
          target_id: r.target_id,
          target_field: r.target_field,
          target_media_type: r.target.media.type,
          details: r.details,
          created_at: r.created_at,
          source_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.source.send(f) rescue nil)]}],
          target_text_fields: Hash[Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.collect{|f| [f, (r.target.send(f) rescue nil)]}],
        }.to_json+"\n")
      end
      f.close
    end
  end
end
