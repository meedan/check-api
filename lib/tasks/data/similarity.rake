# bundle exec rake check:data:similarity
def write_similarity_relationships_to_disk(query, filename)
  puts "Extracting data for accepted suggestions to #{filename}..."
  puts "Using selection query #{query}."
  f = File.open(filename, "w")
  i = 0
  query.find_each do |r|
    i += 1
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

namespace :check do
  namespace :data do
    desc 'Extract similarity data into CSV files.'
    $stdout.sync = true
    task similarity: :environment do |_t, _params|
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
          acl: 'public-read',
          key: object_key,
          body: File.read(file_path),
          bucket: bucket_name,
          content_type: 'application/json'
        )

        response = s3_client.put_object(
          bucket: bucket_name,
          key: object_key,
          body: File.read(file_path)
        )
        if response.etag
          #s3_client.put_object_acl(acl: 'public-read', key: file_path, bucket: bucket_name)
          return true
        else
          return false
        end
      rescue StandardError => e
        puts "Error uploading S3 object: #{e.message}"
        return false
      end

      # Accepted suggestions
      puts 'Preparing accepted.json ...'
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(user: BotUser.alegre_user).where('confirmed_by IS NOT NULL'),
        "/tmp/accepted.json"
      )

      if defined?(ENV.fetch('SIMILARITY_S3_DIR'))
        puts 'Starting upload for accepted.json'
        file_path = '/tmp/accepted.json'
        object_key = "#{ENV['SIMILARITY_S3_DIR']}/accepted.json"
        if object_uploaded?(s3_client, bucket_name, object_key, file_path)
          puts 'Uploaded accepted.json'
        else
          puts 'Error uploading accepted.json to S3. Check credentials?'
        end
      end

      # Automatically matched items
      puts 'Preparing confirmed.json ...'
      write_similarity_relationships_to_disk(
        Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml).where(user: BotUser.alegre_user).where('confirmed_by IS NULL'),
        "/tmp/confirmed.json"
      )

      if defined?(ENV.fetch('SIMILARITY_S3_DIR'))
        puts 'Starting upload for confirmed.json'
        file_path = '/tmp/confirmed.json'
        object_key = "#{ENV['SIMILARITY_S3_DIR']}/confirmed.json"
        if object_uploaded?(s3_client, bucket_name, object_key, file_path)
          puts 'Uploaded confirmed.json'
        else
          puts 'Error uploading confirmed.json to S3. Check credentials?'
        end
      end
    end
  end
end
