ActiveRecord::Base.logger = nil
namespace :check do
  namespace :khousheh do

    PER_PAGE = 2000

    def claim_uuid_for_duplicate_quote
      puts "Collect Claim uuid for duplicate quotes"
      claim_uuid = {}
      Media.select('quote, MIN(id) as first').where(type: 'Claim').group(:quote).having('COUNT(id) > 1')
      .each do |raw|
        claim_uuid[raw['quote']] = raw['first'].to_s
      end
      claim_uuid
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:generate_input_file
    desc 'Generate input files in json format'
    task generate_input_file: :environment do
      started = Time.now.to_i
      # Collect Claim uuid for duplicate quote
      claim_uuid = claim_uuid_for_duplicate_quote
      sort = [{ annotated_id: { order: :asc } }]
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          output = { call_id: feed.uuid, nodes: [], edges: [] }
          Team.current = feed.team
          query = { feed_id: feed.id, feed_view: 'media', show_similar: false }
          es_query = CheckSearch.new(query.to_json).medias_query
          total = CheckSearch.new(query.to_json, nil, feed.team.id).number_of_results
          pages = (total / PER_PAGE.to_f).ceil
          puts "Generating input file for feed #{feed.name} with #{total} item(s)"
          search_after = [0]
          page = 0
          while true
            page += 1
            result = $repository.search(_source: 'annotated_id', query: es_query, sort: sort, search_after: search_after, size: PER_PAGE).results
            pm_ids = result.collect{ |i| i['annotated_id'] }.uniq
            break if pm_ids.empty?
            pm_media_mapping = {}
            uuid = {}
            ProjectMedia.where(id: pm_ids).find_in_batches(:batch_size => PER_PAGE) do |pms|
              print '.'
              # Collect media uuid
              pms.each do |pm|
                pm_media_mapping[pm.id] = pm.media_id
                uuid[pm.media_id] = pm.media_id.to_s
              end
              m_ids = pms.map(&:media_id)
              Media.where(id: m_ids, type: 'Claim').find_each do |m|
               print '.'
               uuid[m.id] = claim_uuid[m.quote] || m.id.to_s
             end
            end
            pm_ids.each do |pm_id|
              m_uuid = uuid[pm_media_mapping[pm_id]]
              output[:nodes] << m_uuid unless output[:nodes].include?(m_uuid)
            end

            Relationship.where(source_id: pm_ids).where('relationship_type = ?', Relationship.confirmed_type.to_yaml)
            .find_in_batches(:batch_size => PER_PAGE) do |relations|
              print '.'
              spm_m_mapping = {}
              tpm_m_mapping = {}
              t_uuid = {}
              target_ids = relations.map(&:target_id)
              # Get ProjectMedia items without Blank medias
              ProjectMedia.where(id: pm_ids).joins(:media).where.not('medias.type': 'Blank').find_each{ |pm| spm_m_mapping[pm.id] = pm.media_id }
              ProjectMedia.where(id: target_ids).joins(:media).where.not('medias.type': 'Blank').find_each do |pm|
                tpm_m_mapping[pm.id] = pm.media_id
                t_uuid[pm.media_id] = pm.media_id.to_s
              end
              Media.where(id: tpm_m_mapping.values, type: 'Claim').find_each do |m|
                print '.'
                t_uuid[m.id] = claim_uuid[m.quote] || m.id.to_s
              end
              relations.each do |r|
                print '.'
                begin
                  if spm_m_mapping.keys.include?(r.source_id) && tpm_m_mapping.keys.include?(r.target_id)
                    output[:edges] << [uuid[spm_m_mapping[r.source_id]], t_uuid[tpm_m_mapping[r.target_id]], r.weight]
                  end
                rescue StandardError => e
                  puts "WARNING: Ignoring corrupted relationship with ID #{r.id} (exception: #{e.message})"
                end
              end
            end
            search_after = [pm_ids.max]
            puts "\nDone for page #{page}/#{pages}\n"
          end
          file = File.open(File.join(Rails.root, 'tmp', "feed-#{feed.uuid}.json"), 'w+')
          file.puts output.to_json
          file.close
          Team.current = nil
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:upload
    desc 'Upload json file to S3'
    task upload: :environment do
      started = Time.now.to_i
      bucket_name = ENV.fetch('CLUSTER_INPUT_BUCKET')
      region = 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts 'Please provide the AWS credentials.'
        exit 1
      end
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          filename = "feed-#{feed.uuid}.json"
          filepath = File.join(Rails.root, 'tmp', filename)
          begin
            response = s3_client.put_object(
              bucket: bucket_name,
              key: object_key,
              body: File.read(file_path)
            )
            if response.etag
              puts "Uploaded #{filename}."
            else
              puts "Error uploading #{filename} to S3. Check credentials?"
            end
          rescue StandardError => e
            puts "Error uploading S3 object: #{e.message}"
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:parse_output_file
    desc 'Parse output file(json format) and recreate clusters'
    task parse_output_file: :environment do
      started = Time.now.to_i
      claim_uuid = claim_uuid_for_duplicate_quote
      sort = [{ annotated_id: { order: :asc } }]
      error_logs = []
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          puts "Downloading feed #{feed.name}"
          begin
            last_old_cluster_id = Cluster.where(feed_id: feed.id).last&.id
            clusters = JSON.parse(File.read(File.join(Rails.root, 'tmp', "#{feed.uuid}.json")))
            started_at = Time.now.to_f
            Cluster.transaction do
              # Create clusters
              mapping = {} # Media ID => Cluster ID
              clusters.each do |media_ids|
                result = Cluster.insert!({ feed_id: feed.id, created_at: Time.now, updated_at: Time.now })
                cluster_id = result[0]['id']
                media_ids.each do |media_id|
                  mapping[media_id.to_i] = cluster_id
                end
              end
              # Add items to clusters
              Team.current = feed.team
              query = { feed_id: feed.id, feed_view: 'media', show_similar: true }
              es_query = CheckSearch.new(query.to_json).medias_query
              total = CheckSearch.new(query.to_json, nil, feed.team.id).number_of_results
              pages = (total / PER_PAGE.to_f).ceil
              search_after = [0]
              page = 0
              while true
                page += 1
                puts "\nIterating on page #{page}/#{pages}\n"
                result = $repository.search(_source: 'annotated_id', query: es_query, sort: sort, search_after: search_after, size: PER_PAGE).results
                pm_ids = result.collect{ |i| i['annotated_id'] }.uniq
                break if pm_ids.empty?
                pm_media_mapping = {}
                uuid = {}
                cpm_items = []
                cluster_items = []
                new_cluster_ids = []
                ProjectMedia.where(id: pm_ids).find_in_batches(:batch_size => PER_PAGE) do |pms|
                  # Collect media uuid
                  pms.each do |pm|
                    pm_media_mapping[pm.id] = pm.media_id
                    uuid[pm.media_id] = pm.media_id.to_s
                  end
                  Media.where(id: pms.map(&:media_id), type: 'Claim').find_each do |m|
                   print '.'
                   uuid[m.id] = claim_uuid[m.quote] || m.id.to_s
                  end
                  # FactCheck
                  pm_fc_mapping = {}
                  ProjectMedia.select('project_medias.id as id, fc.updated_at as fc_updated_at')
                  .where(id: pms.map(&:id))
                  .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
                  .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
                  .find_each do |pm_fc|
                    print '.'
                    pm_fc_mapping[pm_fc['id']] = pm_fc['fc_updated_at']
                  end
                  pms.each do |pm|
                    print '.'
                    cluster_id = mapping[uuid[pm_media_mapping[pm.id]].to_i]
                    next if cluster_id.nil? || new_cluster_ids.include?(cluster_id)
                    cluster = Cluster.find_by_id(cluster_id)
                    next if cluster.nil?
                    new_cluster_ids << cluster_id
                    updated_cluster_attributes = {}
                    updated_cluster_attributes[:id] = cluster.id
                    updated_cluster_attributes[:created_at] = cluster.created_at
                    updated_cluster_attributes[:updated_at] = cluster.updated_at
                    updated_cluster_attributes[:first_item_at] = cluster.first_item_at || pm.created_at
                    updated_cluster_attributes[:last_item_at] = pm.created_at
                    updated_cluster_attributes[:team_ids] = (cluster.team_ids.to_a + [pm.team_id]).uniq.compact_blank
                    updated_cluster_attributes[:channels] = (cluster.channels.to_a + pm.channel.to_h['others'].to_a + [pm.channel.to_h['main']]).uniq.compact_blank
                    updated_cluster_attributes[:media_count] = cluster.media_count + 1
                    updated_cluster_attributes[:requests_count] = cluster.requests_count + pm.requests_count
                    updated_cluster_attributes[:last_request_date] = (pm.last_seen > cluster.last_request_date.to_i) ? Time.at(pm.last_seen) : cluster.last_request_date
                    updated_cluster_attributes[:fact_checks_count] = cluster.fact_checks_count
                    updated_cluster_attributes[:last_fact_check_date] = cluster.last_fact_check_date
                    fact_check = pm.claim_description&.fact_check
                    unless pm_fc_mapping[pm.id].blank?
                      updated_cluster_attributes[:fact_checks_count] = cluster.fact_checks_count + 1
                      updated_cluster_attributes[:last_fact_check_date] = pm_fc_mapping[pm.id] if pm_fc_mapping[pm.id].to_i > cluster.last_fact_check_date.to_i
                    end
                    cpm_items << { project_media_id: pm.id, cluster_id: cluster_id }
                    # FIXME: Set the center of the cluster properly
                    updated_cluster_attributes[:project_media_id] = cluster.project_media_id || pm
                    cluster_items << updated_cluster_attributes
                  end
                end
                # Bulk-insert ClusterProjectMedia
                unless cpm_items.blank?
                  begin
                    ClusterProjectMedia.insert_all(cpm_items, unique_by: %i[ cluster_id project_media_id ])
                  rescue
                    error_logs << {feed: "Failed to import ClusterProjectMedia for feed #{feed.id} page #{page}"}
                  end
                end
                # Bulk-update Cluster
                unless cluster_items.blank?
                  begin
                    Cluster.upsert_all(cluster_items)
                  rescue
                    error_logs << {feed: "Failed to update Cluster for feed #{feed.id} page #{page}"}
                  end
                end
                search_after = [pm_ids.max]
              end
              Team.current = nil
              # Delete old clusters
              Cluster.where(feed_id: feed.id).where('id <= ?', last_old_cluster_id).delete_all unless last_old_cluster_id.nil?
              feed.update_column(:last_clusterized_at, Time.now)
            end
            puts "Rebuilding clusters for feed #{feed.name} took #{Time.now.to_f - started_at} seconds."
          rescue Errno::ENOENT
            puts "Output file not found for feed #{feed.name}"
          end
        end
      end
      puts "Logs:: #{error_logs.inspect}" unless error_logs.blank?
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:download
    desc 'Download json file from S3'
    task download: :environment do
      started = Time.now.to_i
      # TODO: download json file from S3
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
