ActiveRecord::Base.logger = nil
namespace :check do
  namespace :khousheh do

    PER_PAGE = 2000

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:upload
    desc 'Generate input files and upload to S3'
    task upload: :environment do |_t, args|
      started = Time.now.to_i
      sort = [{ annotated_id: { order: :asc } }]
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          puts "Uploading feed #{feed.name}"
          output = { call_id: feed.uuid, nodes: [], edges: [] }
          Team.current = feed.team
          query = { feed_id: feed.id, feed_view: 'media', show_similar: false }
          es_query = CheckSearch.new(query.to_json).medias_query
          total = CheckSearch.new(query.to_json, nil, feed.team.id).number_of_results
          pages = (total / PER_PAGE.to_f).ceil
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
              # Collect media uuid
              pms.each{|pm| pm_media_mapping[pm.id] = pm.media_id }
              Media.where(id: pms.map(&:media_id)).find_each{|m| uuid[m.id] = m.uuid.to_s }
            end
            pm_ids.each do |pm_id|
              m_uuid = uuid[pm_media_mapping[pm_id]]
              output[:nodes] << m_uuid unless output[:nodes].include?(m_uuid)
            end

            Relationship.where(source_id: pm_ids).where('relationship_type = ?', Relationship.confirmed_type.to_yaml)
            .find_in_batches(:batch_size => PER_PAGE) do |relations|
              spm_m_mapping = {}
              tpm_m_mapping = {}
              target_ids = relations.map(&:target_id)
              # Get items without Blank items
              ProjectMedia.where(id: target_ids).joins(:media).where.not('medias.type': 'Blank').find_each{ |pm| tpm_m_mapping[pm.id] = pm.media_id }
              ProjectMedia.where(id: pm_ids).joins(:media).where.not('medias.type': 'Blank').find_each{ |pm| spm_m_mapping[pm.id] = pm.media_id }
              t_uuid = {}
              Media.where(id: tpm_m_mapping.values).find_each{ |m| t_uuid[m.id] = m.uuid.to_s }
              relations.each do |r|
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
            puts "Done for page #{page}/#{pages}"
          end
          file = File.open(File.join(Rails.root, 'tmp', "feed-#{feed.uuid}.json"), 'w+')
          file.puts output.to_json
          file.close
          Team.current = nil
          # FIXME: Upload to S3
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:download
    desc 'Download output files from S3 and recreate clusters'
    task download: :environment do |_t, args|
      started = Time.now.to_i
      # FIXME: Download from S3
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
              total = CheckSearch.new(query.to_json, nil, feed.team.id).number_of_results
              pages = (total / PER_PAGE.to_f).ceil
              pages.times do |page|
                puts "Iterating on page #{page + 1}/#{pages}"
                CheckSearch.new(query.merge({ esoffset: (page * PER_PAGE), eslimit: PER_PAGE }).to_json, nil, feed.team.id).medias.order('created_at ASC').find_each do |pm|
                  cluster_id = mapping[pm.media.uuid]
                  next if cluster_id.nil?
                  cluster = Cluster.find(cluster_id)
                  updated_cluster_attributes = {}
                  updated_cluster_attributes[:first_item_at] = cluster.first_item_at || pm.created_at
                  updated_cluster_attributes[:last_item_at] = pm.created_at
                  updated_cluster_attributes[:team_ids] = (cluster.team_ids.to_a + [pm.team_id]).uniq.compact_blank
                  updated_cluster_attributes[:channels] = (cluster.channels.to_a + pm.channel.to_h['others'].to_a + [pm.channel.to_h['main']]).uniq.compact_blank
                  updated_cluster_attributes[:media_count] = cluster.media_count + 1
                  updated_cluster_attributes[:requests_count] = cluster.requests_count + pm.requests_count
                  updated_cluster_attributes[:last_request_date] = Time.at(pm.last_seen) if pm.last_seen > cluster.last_request_date.to_i
                  fact_check = pm.claim_description&.fact_check
                  unless fact_check.nil?
                    updated_cluster_attributes[:fact_checks_count] = cluster.fact_checks_count + 1
                    updated_cluster_attributes[:last_fact_check_date] = fact_check.updated_at if fact_check.updated_at.to_i > cluster.last_fact_check_date.to_i
                  end
                  # FIXME: Set the center of the cluster properly
                  updated_cluster_attributes[:project_media_id] = cluster.project_media_id || pm.id
                  updated_cluster_attributes[:title] = cluster.title || pm.title
                  cluster.update_columns(updated_cluster_attributes)
                  ClusterProjectMedia.insert!({ cluster_id: cluster_id, project_media_id: pm.id })
                end
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
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
