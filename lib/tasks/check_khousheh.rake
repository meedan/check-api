ActiveRecord::Base.logger = nil
namespace :check do
  namespace :khousheh do

    PER_PAGE = Rails.env.development? ? 10 : 2000

    TIMESTAMP = Time.now.to_f.to_s.gsub('.', '')

    def print_task_title(title)
      puts '----------------------------------------------------------------'
      puts title.upcase + '...'
      puts '----------------------------------------------------------------'
      puts
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:generate_input
    desc 'Generate input files in JSON format.'
    task generate_input: :environment do
      print_task_title 'Generating input files'
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', 'feed-clusters-input'))
      started = Time.now.to_i
      sort = [{ annotated_id: { order: :asc } }]
      all_types = CheckSearch::MEDIA_TYPES + ['blank']
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          output = { call_id: "#{TIMESTAMP}-#{feed.uuid}", nodes: [], edges: [] }
          Team.current = feed.team
          query = { feed_id: feed.id, feed_view: 'media', show_similar: true, show: all_types }
          es_query = CheckSearch.new(query.to_json).medias_query
          total = CheckSearch.new(query.to_json, nil, feed.team.id).number_of_results
          pages = (total / PER_PAGE.to_f).ceil
          puts "Generating input file for feed #{feed.name} with #{total} item(s)..."
          search_after = [0]
          page = 0
          while true
            page += 1
            result = $repository.search(_source: 'annotated_id', query: es_query, sort: sort, search_after: search_after, size: PER_PAGE).results
            pm_ids = result.collect{ |i| i['annotated_id'] }.uniq
            break if pm_ids.empty?
            pm_media_mapping = {} # Project Media ID => Media ID
            uuid = {}
            ProjectMedia.where(id: pm_ids).find_in_batches(:batch_size => PER_PAGE) do |pms|
              print '.'
              # Collect media UUID
              pms.each do |pm|
                pm_media_mapping[pm.id] = pm.media_id
                uuid[pm.media_id] = pm.media_id.to_s
              end
              m_ids = pms.map(&:media_id)
              Media.where(id: m_ids, type: 'Claim').find_each do |m|
                print '.'
                uuid[m.id] = m.uuid.to_s
              end
            end
            pm_ids.each do |pm_id|
              m_uuid = uuid[pm_media_mapping[pm_id]]
              next if m_uuid.blank?
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
                t_uuid[m.id] = m.uuid.to_s
              end
              relations.each do |r|
                print '.'
                begin
                  if spm_m_mapping.keys.include?(r.source_id) && tpm_m_mapping.keys.include?(r.target_id)
                    if !uuid[spm_m_mapping[r.source_id]].blank? && !t_uuid[tpm_m_mapping[r.target_id]].blank?
                      output[:edges] << [uuid[spm_m_mapping[r.source_id]], t_uuid[tpm_m_mapping[r.target_id]], r.weight]
                    end
                  end
                rescue StandardError => e
                  puts "WARNING: Ignoring corrupted relationship with ID #{r.id} (exception: #{e.message})"
                end
              end
            end
            search_after = [pm_ids.max]
            puts "\nDone for page #{page}/#{pages}\n"
          end
          output_file_path = File.join(Rails.root, 'tmp', 'feed-clusters-input', "#{TIMESTAMP}-#{feed.uuid}.json")
          file = File.open(output_file_path, 'w+')
          file.puts output.to_json
          file.close
          puts "[#{Time.now}] Output file saved to #{output_file_path}."
          Team.current = nil
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 -e CLUSTER_INPUT_BUCKET=bucket-name api bundle exec rake check:khousheh:upload
    desc 'Upload input JSON files to S3.'
    task upload: [:environment, :generate_input] do
      print_task_title 'Uploading input files'
      started = Time.now.to_i
      bucket_name = ENV.fetch('CLUSTER_INPUT_BUCKET')
      region = CheckConfig.get('storage_bucket_region') || 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts 'Please provide the AWS credentials.'
      end
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          filename = "#{TIMESTAMP}-#{feed.uuid}.json"
          filepath = File.join(Rails.root, 'tmp', 'feed-clusters-input', filename)
          response = s3_client.put_object(
            bucket: bucket_name,
            key: filename,
            body: File.read(filepath)
          )
          if response.etag
            puts "Uploaded #{filename}."
          else
            puts "Error uploading #{filename} to S3."
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 -e CLUSTER_OUTPUT_BUCKET=bucket-name api bundle exec rake check:khousheh:download
    desc 'Download json file from S3'
    task download: [:environment, :upload] do
      print_task_title 'Downloading output files'
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', 'feed-clusters-output'))
      started = Time.now.to_i
      bucket_name = ENV.fetch('CLUSTER_OUTPUT_BUCKET')
      region = CheckConfig.get('storage_bucket_region') || 'eu-west-1'
      s3_client = Aws::S3::Client.new(region: region)
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          filename = "#{TIMESTAMP}-#{feed.uuid}.json"
          filepath = File.join(Rails.root, 'tmp', 'feed-clusters-output', filename)
          # Try during one hour
          attempts = 0
          object = nil
          while attempts < 60 && object.nil?
            begin
              object = s3_client.get_object(bucket: bucket_name, key: filename)
            rescue StandardError => e
              puts "File #{filename} not found in bucket #{bucket_name}, trying again in 1 minute..."
              sleep 60
              attempts += 1
            end
          end
          if object.nil?
            puts "Aborting. File #{filename} not found in bucket #{bucket_name}."
          else
            file = File.open(File.join(Rails.root, 'tmp', 'feed-clusters-output', "#{TIMESTAMP}-#{feed.uuid}.json"), 'w+')
            file.puts object.body.read
            file.close
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:parse_output
    desc 'Parse output files (JSON format) and recreate clusters.'
    task parse_output: [:environment, :download] do
      print_task_title 'Parsing output files'
      started = Time.now.to_i
      sort = [{ annotated_id: { order: :asc } }]
      error_logs = []
      Feed.find_each do |feed|
        last_old_cluster_id = Cluster.where(feed_id: feed.id).order('id ASC').last&.id
        puts "Parsing feed #{feed.name}..."
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          begin
            last_old_cluster_id = Cluster.where(feed_id: feed.id).order('id ASC').last&.id
            clusters = JSON.parse(File.read(File.join(Rails.root, 'tmp', 'feed-clusters-output', "#{TIMESTAMP}-#{feed.uuid}.json")))
            started_at = Time.now.to_f
            Cluster.transaction do
              # Create clusters
              mapping = {} # Media ID => Cluster ID
              # Cluster to delete in case there is no center (project_media_id)
              cluster_to_delete = []
              # Bulk-insert clusters
              c_inserted_items = []
              clusters.length.times.each_slice(2500) do |rows|
                print '.'
                c_items = []
                rows.each { |r| c_items << { feed_id: feed.id, created_at: Time.now, updated_at: Time.now } }
                output = Cluster.insert_all(c_items)
                c_inserted_items.concat(output.rows.flatten)
              end
              clusters.each.with_index do |media_ids, i|
                cluster_id = c_inserted_items[i]
                media_ids.each do |media_id|
                  mapping[media_id.to_i] = cluster_id
                end
              end
              # Add items to clusters
              Team.current = feed.team
              all_types = CheckSearch::MEDIA_TYPES + ['blank']
              query = { feed_id: feed.id, feed_view: 'media', show_similar: true, show: all_types }
              es_query = CheckSearch.new(query.to_json).medias_query
              total = CheckSearch.new(query.to_json, nil, feed.team.id).number_of_results
              pages = (total / PER_PAGE.to_f).ceil
              search_after = [0]
              page = 0
              processed = []
              while true
                result = $repository.search(_source: 'annotated_id', query: es_query, sort: sort, search_after: search_after, size: PER_PAGE).results
                pm_ids = result.collect{ |i| i['annotated_id'] }.uniq
                break if pm_ids.empty?

                # Append IDs of child items but ignore the ones that were already processed
                pm_ids += Relationship.where(source_id: pm_ids).where('relationship_type = ?', Relationship.confirmed_type.to_yaml).select(:target_id).map(&:target_id)
                pm_ids.uniq!
                pm_ids.reject!{ |id| processed.include?(id) }
                processed += pm_ids

                page += 1
                puts "\nIterating on page #{page}/#{pages}\n"
                pm_media_mapping = {} # Project Media ID => Media ID
                uuid = {}
                cluster_items = {}
                cpm_items = []
                ProjectMedia.where(id: pm_ids).find_in_batches(:batch_size => PER_PAGE) do |pms|
                  # Collect claim media UUIDs
                  pms.each do |pm|
                    pm_media_mapping[pm.id] = pm.media_id
                    uuid[pm.media_id] = pm.media_id.to_s
                  end
                  Media.where(id: pms.map(&:media_id), type: 'Claim').find_each do |m|
                    print '.'
                    uuid[m.id] = m.uuid.to_s
                  end
                  # Fact-checks
                  pm_fc_mapping = {} # Project Media ID => Fact-Check Updated At
                  ProjectMedia.select('project_medias.id as id, fc.updated_at as fc_updated_at')
                  .where(id: pms.select{ |pm| pm.report_status == 'published' }.map(&:id))
                  .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
                  .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
                  .find_each do |pm_fc|
                    print '.'
                    pm_fc_mapping[pm_fc['id']] = pm_fc['fc_updated_at']
                  end
                  # Local clusters
                  pms.each do |pm|
                    print '.'
                    cluster_id = mapping[uuid[pm_media_mapping[pm.id]].to_i]
                    next if cluster_id.nil?
                    cluster = nil
                    if cluster_items[cluster_id]
                      cluster = OpenStruct.new(cluster_items[cluster_id])
                    else
                      cluster = Cluster.find_by_id(cluster_id)
                    end
                    next if cluster.nil?
                    updated_cluster_attributes = { id: cluster.id, created_at: cluster.created_at, updated_at: Time.now }
                    updated_cluster_attributes[:first_item_at] = cluster.first_item_at || pm.created_at
                    updated_cluster_attributes[:last_item_at] = pm.created_at
                    updated_cluster_attributes[:team_ids] = (cluster.team_ids.to_a + [pm.team_id]).uniq.compact_blank
                    updated_cluster_attributes[:channels] = (cluster.channels.to_a + pm.channel.to_h['others'].to_a + [pm.channel.to_h['main']]).uniq.compact_blank
                    updated_cluster_attributes[:media_count] = cluster.media_count + 1
                    updated_cluster_attributes[:requests_count] = cluster.requests_count + pm.requests_count
                    updated_cluster_attributes[:last_request_date] = (pm.tipline_requests.last&.created_at.to_i > cluster.last_request_date.to_i) ? pm.tipline_requests.last.created_at : cluster.last_request_date
                    updated_cluster_attributes[:fact_checks_count] = cluster.fact_checks_count
                    updated_cluster_attributes[:last_fact_check_date] = cluster.last_fact_check_date
                    unless pm_fc_mapping[pm.id].blank?
                      updated_cluster_attributes[:fact_checks_count] = cluster.fact_checks_count + 1
                      updated_cluster_attributes[:last_fact_check_date] = pm_fc_mapping[pm.id] if pm_fc_mapping[pm.id].to_i > cluster.last_fact_check_date.to_i
                    end
                    cpm_items << { project_media_id: pm.id, cluster_id: cluster.id }
                    cluster_center = CheckClusterCenter.replace_or_keep_cluster_center(cluster.project_media_id, pm)
                    updated_cluster_attributes[:project_media_id] = cluster_center
                    cluster_title = cluster_center == pm.id ? pm.title : cluster.title
                    updated_cluster_attributes[:title] = cluster_title
                    # Update cluster
                    if updated_cluster_attributes[:project_media_id].blank?
                      cluster_to_delete << cluster.id
                      error_logs << {Cluster: "Failed to update Cluster with id #{cluster.id}"}
                    else
                      cluster_items[cluster.id] = updated_cluster_attributes
                    end
                  end
                end
                # Bulk-update Cluster
                unless cluster_items.blank?
                  begin
                    cluster_items_values = cluster_items.values.to_a
                    Cluster.upsert_all(cluster_items_values, unique_by: :id)
                  rescue
                    error_logs << {feed: "Failed to import Cluster for feed #{feed.id} page #{page}"}
                  end
                end
                # Bulk-insert ClusterProjectMedia
                unless cpm_items.blank?
                  begin
                    ClusterProjectMedia.insert_all(cpm_items, unique_by: %i[ cluster_id project_media_id ])
                  rescue
                    error_logs << { feed: "Failed to import ClusterProjectMedia for feed #{feed.id} page #{page}" }
                  end
                end
                search_after = [pm_ids.max]
              end
              # Delete cluster with no project_media_id
              Cluster.where(id: cluster_to_delete).delete_all
              Team.current = nil
            end
            puts "\nRebuilding clusters for feed #{feed.name} took #{Time.now.to_f - started_at} seconds."
          rescue Errno::ENOENT
            puts "\nOutput file not found for feed #{feed.name}."
          end
        end
        # Delete old clusters
        unless last_old_cluster_id.nil?
          deleted_clusters = Cluster.where(feed_id: feed.id).where('id <= ?', last_old_cluster_id).map(&:id)
          unless deleted_clusters.blank?
            ClusterProjectMedia.where(cluster_id: deleted_clusters).delete_all
            Cluster.where(id: deleted_clusters).delete_all
          end
        end
        feed.update_column(:last_clusterized_at, Time.now)
      end
      puts "Logs: #{error_logs.inspect}." unless error_logs.blank?
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 -e CLUSTER_INPUT_BUCKET=bucket-name -e CLUSTER_OUTPUT_BUCKET=bucket-name api bundle exec rake check:khousheh:rebuild
    desc 'Rebuild clusters.'
    task rebuild: [:environment, :parse_output] do
      print_task_title "[#{TIMESTAMP}] Rebuilding clusters"
    end
  end
end
