# bundle exec rake check:data:similarityunc

def write_archived_similarity_relationships_to_disk(object_change, filename)
  puts "Extracting data for archived suggestions to #{filename}..."
  f = File.open(filename, "w")
  tids = Team.all.map(&:id)
  tids.each_with_index do |tid, i|
    j = 0
      Version.from_partition(tid).where(item_type: 'Relationship', event: 'destroy', created_at: Time.now.ago(12.weeks)..Time.now).where('object_changes SIMILAR TO ?', object_change).find_each do |v|
      j += 1
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
    task similarityunc: :environment do |_t, _params|
      $stdout.sync = true
      bucket_name = 'check-batch-task-similarity'
      region = 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts "Please provide the AWS credentials."
        exit 1
      end

      def object_uploaded?(s3_client, bucket_name, object_key, file_path)
        puts "Attempting S3 upload to #{bucket_name} for key #{object_key} ..."
        response = s3_client.put_object(
          bucket: bucket_name,
          key: object_key,
          body: File.read(file_path)
        )
        if response.etag
          return true
        else
          return false
        end
      rescue StandardError => e
        puts "Error uploading S3 object: #{e.message}"
        return false
      end

      # Rejected suggestions -- either destroyed suggests or destoryed confirmed matches that started as a suggestion
      puts 'Preparing rejected.json ...'
      write_archived_similarity_relationships_to_disk(
        "(%suggested\\_sibling%)|(%confirmed\\_sibling%user\\_id\":\\[#{BotUser.alegre_user.id}%\"confirmed\\_by\":\\[[0-9]%)",
        "/tmp/rejected.json"
      )

      if defined?(ENV.fetch('SIMILARITY_S3_DIR'))
        puts 'Starting upload for rejected.json'
        file_path = '/tmp/rejected.json'
        object_key = "#{ENV['SIMILARITY_S3_DIR']}/rejected.json"
        if object_uploaded?(s3_client, bucket_name, object_key, file_path)
          puts 'Uploaded rejected.json'
        else
          puts 'Error uploading rejected.json to S3. Check credentials?'
        end
      end

      # Manually created matches
      puts 'Preparing manual.json ...'
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where.not(user: BotUser.alegre_user),
        "/tmp/manual.json"
      )

      if defined?(ENV.fetch('SIMILARITY_S3_DIR'))
        puts 'Starting upload for manual.json'
        file_path = '/tmp/manual.json'
        object_key = "#{ENV['SIMILARITY_S3_DIR']}/manual.json"
        if object_uploaded?(s3_client, bucket_name, object_key, file_path)
          puts 'Uploaded manual.json'
        else
          puts 'Error uploading manual.json to S3. Check credentials?'
        end
      end

      # Manually detached matches
      puts 'Preparing detached.json ...'
      write_archived_similarity_relationships_to_disk(
        "%confirmed\\_sibling%user\\_id\":\\[4588%\"confirmed\\_by\":\\[null%",
        "/tmp/detached.json"
      )

      if defined?(ENV.fetch('SIMILARITY_S3_DIR'))
        puts 'Starting upload for detached.json'
        file_path = '/tmp/detached.json'
        object_key = "#{ENV['SIMILARITY_S3_DIR']}/detached.json"
        if object_uploaded?(s3_client, bucket_name, object_key, file_path)
          puts 'Uploaded detached.json'
        else
          puts 'Error uploading detached.json to S3. Check credentials?'
        end
      end

      # Suggestions
      puts 'Preparing suggestions.json ...'
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml),
        "/tmp/suggestions.json"
      )

      if defined?(ENV.fetch('SIMILARITY_S3_DIR'))
        puts 'Starting uploaded for suggestions.json'
        file_path = '/tmp/suggestions.json'
        object_key = "#{ENV['SIMILARITY_S3_DIR']}/suggestions.json"
        if object_uploaded?(s3_client, bucket_name, object_key, file_path)
          puts 'Uploaded suggestions.json'
        else
          puts 'Error uploading suggestions.json to S3. Check credentials?'
        end
      end
    end
  end
end
