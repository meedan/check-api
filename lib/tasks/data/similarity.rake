# bundle exec rake check:data:similarity

namespace :check do
  namespace :data do
    desc 'Extract similarity data into CSV files.'
    task similarity: :environment do |_t, _params|
      # Accepted suggestions
      puts 'Extracting data for accepted suggestions to /tmp/accepted.csv...'
      o = File.open('/tmp/accepted.csv', 'w+')
      o.puts('Workspace Slug,Weight,Main Item ID,Main Item Type,Secondary Item ID,Secondary Item Type,Timestamp')
      i = 0
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(user: BotUser.alegre_user).where('confirmed_by IS NOT NULL').find_each do |r|
        i += 1
        puts("Relationship #{i}")
        o.puts([r.source.team.slug, r.weight, r.source_id, r.source.media.type, r.target_id, r.target.media.type, r.created_at].join(','))
      end
      o.close

      # Rejected suggestions
      puts 'Extracting data for rejected suggestions to /tmp/rejected.csv...'
      o = File.open('/tmp/rejected.csv', 'w+')
      o.puts('Workspace Slug,Weight,Main Item ID,Main Item Type,Secondary Item ID,Secondary Item Type,Timestamp')
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
          o.puts([source.team.slug, r['weight'], source.id, source.media.type, target.id, target.media.type, r['created_at']].join(','))
        end
      end
      o.close

      # Manually created matches
      puts 'Extracting data for manual matches to /tmp/manual.csv...'
      o = File.open('/tmp/manual.csv', 'w+')
      o.puts('Workspace Slug,Weight,Main Item ID,Main Item Type,Secondary Item ID,Secondary Item Type,Timestamp')
      i = 0
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where.not(user: BotUser.alegre_user).find_each do |r|
        i += 1
        puts("Relationship #{i}")
        o.puts([r.source.team.slug, r.weight, r.source_id, r.source.media.type, r.target_id, r.target.media.type, r.created_at].join(','))
      end
      o.close

      # Manually detached matches
      puts 'Extracting data for detached matches to /tmp/detached.csv...'
      o = File.open('/tmp/detached.csv', 'w+')
      o.puts('Workspace Slug,Weight,Main Item ID,Main Item Type,Secondary Item ID,Secondary Item Type,Timestamp')
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
          o.puts([source.team.slug, r['weight'], source.id, source.media.type, target.id, target.media.type, r['created_at']].join(','))
        end
      end
      o.close

      # Suggestions
      puts 'Extracting data for suggestions to /tmp/suggestions.csv...'
      o = File.open('/tmp/suggestions.csv', 'w+')
      o.puts('Workspace Slug,Weight,Main Item ID,Main Item Type,Secondary Item ID,Secondary Item Type,Timestamp')
      i = 0
      Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml).find_each do |r|
        i += 1
        puts("Relationship #{i}")
        o.puts([r.source.team.slug, r.weight, r.source_id, r.source.media.type, r.target_id, r.target.media.type, r.created_at].join(','))
      end
      o.close
    end
  end
end
