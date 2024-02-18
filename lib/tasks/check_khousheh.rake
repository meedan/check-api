ActiveRecord::Base.logger = nil
namespace :check do
  namespace :khousheh do

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:upload
    desc 'Generate input files and upload to S3'
    task upload: :environment do |_t, args|
      Feed.find_each do |feed|
        # Only feeds that are sharing media
        if feed.data_points.to_a.include?(2)
          puts "Uploading feed #{feed.name}"
          output = { call_id: feed.uuid, nodes: [], edges: [] }
          Team.current = feed.team
          CheckSearch.new({ feed_id: feed.id, feed_view: 'media' }.to_json, nil, feed.team.id).medias.find_each do |pm|
            print '.'
            output[:nodes] << pm.media.uuid.to_s unless output[:nodes].include?(pm.media.uuid.to_s)
            Relationship.where(source_id: pm.id).where('relationship_type = ?', Relationship.confirmed_type.to_yaml).find_each do |r|
              begin
                next if r.source.media.is_a?(Blank) || r.target.media.is_a?(Blank)
                output[:edges] << [r.source.media.uuid.to_s, r.target.media.uuid.to_s, r.weight]
              rescue StandardError => e
                puts "WARNING: Ignoring corrupted relationship with ID #{r.id} (exception: #{e.message})"
              end
            end
          end
          file = File.open(File.join(Rails.root, 'tmp', "feed-#{feed.uuid}.json"), 'w+')
          file.puts output.to_json
          file.close
          puts
          Team.current = nil
          # FIXME: Upload to S3
        end
      end
    end

    # docker-compose exec -e elasticsearch_log=0 api bundle exec rake check:khousheh:download
    desc 'Download output files from S3 and recreate clusters'
    task download: :environment do |_t, args|
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
              CheckSearch.new({ feed_id: feed.id, feed_view: 'media' }.to_json, nil, feed.team.id).medias.order('created_at ASC').find_each do |pm|
                cluster_id = mapping[pm.media.uuid]
                next if cluster_id.nil?
                cluster = Cluster.find(cluster_id)
                updated_cluster_attributes = {}
                updated_cluster_attributes[:first_item_at] = cluster.first_item_at || pm.created_at
                updated_cluster_attributes[:last_item_at] = pm.created_at
                updated_cluster_attributes[:team_ids] = (cluster.team_ids.to_a + [pm.team_id]).uniq.compact_blank
                updated_cluster_attributes[:channels] = (cluster.channels.to_a + pm.channel.to_h['others'].to_a + [pm.channel.to_h['main']]).uniq.compact_blank
                updated_cluster_attributes[:media_count] = cluster.media_count + 1
                updated_cluster_attributes[:requests_count] = cluster.requests_count + pm.demand
                updated_cluster_attributes[:last_request_date] = Time.at(pm.last_seen) if pm.last_seen > cluster.last_request_date.to_i
                fact_check = pm.claim_description&.fact_check
                unless fact_check.nil?
                  updated_cluster_attributes[:fact_checks_count] = cluster.fact_checks_count + 1
                  updated_cluster_attributes[:last_fact_check_date] = fact_check.updated_at if fact_check.updated_at.to_i > cluster.last_fact_check_date.to_i
                end
                rows = [{ project_media_id: pm.id, cluster_id: cluster_id }]
                Relationship.where(source_id: pm.id).where('relationship_type = ?', Relationship.confirmed_type.to_yaml).find_each do |r|
                  rows << { project_media_id: r.target_id, cluster_id: cluster_id }
                  updated_cluster_attributes[:media_count] += 1
                end
                ClusterProjectMedia.insert_all(rows)
                # FIXME: Set the center of the cluster properly
                updated_cluster_attributes[:project_media_id] = cluster.project_media_id || pm.id
                cluster.update_columns(updated_cluster_attributes)
              end
              Team.current = nil

              # Delete old clusters
              Cluster.where(feed_id: feed.id).where('id <= ?', last_old_cluster_id).delete_all unless last_old_cluster_id.nil?
            end
            puts "Rebuilding clusters for feed #{feed.name} took #{Time.now.to_f - started_at} seconds."
          rescue Errno::ENOENT
            puts "Output file not found for feed #{feed.name}"
          end
        end
      end
    end
  end
end
