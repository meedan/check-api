namespace :check do
  namespace :migrate do
    task :add_team_id_to_versions, [:mapping_cache_json_file, :last_cached_version_id] => :environment do |t, args|
      last_id = Rails.cache.read('check:migrate:versions_team_id:last_id')
      raise "Cache key check:migrate:versions_team_id:last_id not found! Aborting." if last_id.nil?

      puts "[#{Time.now}] Grouping versions by team..."

      # Key: Team ID, Value: Version ID to be updated
      mapping = {}

      if args.mapping_cache_json_file
        mapping = JSON.parse(File.read(args.mapping_cache_json_file))
      end

      first_id = 0
      if args.last_cached_version_id
        first_id = args.last_cached_version_id
      end

      n = Version.where('id <= ?', last_id).where('id > ?', first_id).count
      i = 0
      Version.where('id <= ?', last_id).where('id > ?', first_id).find_each(batch_size: 10000).each do |version|
        i += 1
        print "#{i}/#{n} versions processed...\r"
        $stdout.flush
        team_id = version.get_team_id
        if team_id.nil?
          assoc = version.associated
          team_id = assoc.team&.id if assoc
        end
        next if team_id.nil?
        mapping[team_id] ||= []
        mapping[team_id] << version.id
      end

      unless args.mapping_cache_json_file
        puts "[#{Time.now}] Saving mapping to external file..."
        f = File.open('versions-team-ids.json', 'w+')
        f.puts(mapping.to_json)
        f.close
      end

      puts "[#{Time.now}] Now let's update the team_id of each version..."

      n = mapping.keys.size
      i = 0
      mapping.each do |team_id, version_ids|
        i += 1
        version_ids.each_slice(10000).to_a.each do |some_version_ids|
          Version.where(id: some_version_ids).update_all(team_id: team_id)
        end
        print "#{i}/#{n} teams processed...\r"
        $stdout.flush
      end

      puts "[#{Time.now}] Now let's move the items to the partitions..."

      n = mapping.keys.size
      i = 0
      mapping.keys.each do |team_id|
        i += 1
        while ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM ONLY versions WHERE team_id = #{team_id}")[0]['count'].to_i > 0
          ActiveRecord::Base.connection.execute("INSERT INTO \"versions_partitions\".\"p#{team_id}\" (SELECT * FROM ONLY versions WHERE team_id = #{team_id} ORDER BY id ASC LIMIT 10000)")
          ActiveRecord::Base.connection.execute("DELETE FROM ONLY versions WHERE id IN (SELECT id FROM ONLY versions WHERE team_id = #{team_id} ORDER BY id ASC LIMIT 10000)")
        end
        print "#{i}/#{n} teams processed...\r"
        $stdout.flush
      end
      
      puts "[#{Time.now}] Now let's move the items without team_id to the partition zero..."

      while ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM ONLY versions WHERE team_id IS NULL")[0]['count'].to_i > 0
        ActiveRecord::Base.connection.execute("INSERT INTO \"versions_partitions\".\"p0\" (SELECT * FROM ONLY versions WHERE team_id IS NULL ORDER BY id ASC LIMIT 10000)")
        ActiveRecord::Base.connection.execute("DELETE FROM ONLY versions WHERE id IN (SELECT id FROM ONLY versions WHERE team_id IS NULL ORDER BY id ASC LIMIT 10000)")
      end
      
      puts "[#{Time.now}] Done!"
      
      Rails.cache.delete('check:migrate:versions_team_id:last_id')
    end
  end
end
