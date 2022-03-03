def log(text)
  puts text
  puts
end

namespace :check do
  namespace :clusters do
    # bundle exec rake check:clusters:rebuild[list of team slugs]
    desc 'Rebuild similarity clusters from scratch by calling Alegre API'
    task rebuild: :environment do |_t, args|

      # Get the team IDs from the team slugs passed as input parameters
      team_ids = Team.where(slug: args.to_a.map(&:to_s)).all.map(&:id)

      # Delete existing clusters
      log 'Resetting all cluster IDs to null...'
      centers = Cluster.all.map(&:project_media_id)
      Cluster.delete_all
      ProjectMedia.where.not(cluster_id: nil).update_all(cluster_id: nil)
      # Reset fields in ElasticSearch
      es_body = []
      centers.each do |id|
        es_body << {
          update: {
            _index: ::CheckElasticSearchModel.get_index_alias,
            _id: Base64.encode64("ProjectMedia/#{id}"),
            retry_on_conflict: 3,
            data: {
              doc: {
                cluster_size: 0,
                cluster_report_published: 0,
                cluster_first_item_at: 0,
                cluster_last_item_at: 0,
                cluster_published_reports_count: 0,
                cluster_requests_count: 0
              }
            }
          }
        }
      end
      $repository.client.bulk(body: es_body) unless es_body.empty?
      log 'Done.'

      # Set the clusters for all media types
      ['text', 'image', 'audio', 'video'].each do |type|
        log "-----------------------------------\nComputing cluster for #{type}\n-----------------------------------"

        # If there is no existing cluster computation in progress, request a new one and save the ID in a file
        key = File.join(Rails.root, 'tmp', "check:clusters:rebuild:job_id:#{type}")
        job_id = File.exists?(key) ? File.read(key).chomp.to_i : nil
        if job_id.nil?
          log "Cache key not found: #{key}"
          context = {
            team_id: team_ids,
            has_custom_id: true
          }
          context[:field] = ::Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS if type == 'text'
          params = {
            threshold: ::Bot::Alegre.get_threshold_for_query(type, ProjectMedia.new(team_id: 0), true)[:value],
            data_types: [type],
            context: context
          }
          log "Requesting Alegre: POST /graph/cluster with payload #{params.to_json}"
          response = ::Bot::Alegre.request_api('post', '/graph/cluster/', params)
          job_id = response['graph_id']
          File.write(key, job_id)
        end

        # Loop requests to Alegre until the cluster is computed
        params = { graph_id: job_id }
        log "Requesting Alegre: GET /graph/cluster with payload #{params.to_json}"
        response = ::Bot::Alegre.request_api('get', '/graph/cluster/', params)
        while response.dig('graph', 'status') != 'enriched'
          log "Cluster not ready for #{job_id}, response was: #{response.to_json}. Retrying in 5 seconds..."
          sleep 5
          response = ::Bot::Alegre.request_api('get', '/graph/cluster/', params)
        end
        log "Cluster is ready for #{job_id}, response was: #{response.to_json}"

        # Iterate through the results: set cluster_id for each relevant item in the response
        response['clusters'].each do |cluster|
          ids = []
          cluster.each do |node|
            id = node.dig('context', 0, 'project_media_id') unless node['context'].blank?
            unless id
              id = begin Base64.decode64(node['data_type_id']).match(/^check-project_media-([0-9]+)-.*$/)[1].to_i rescue 0 end
            end
            ids << id if id.to_i > 0
          end
          next if ids.empty?
          cluster_obj = nil
          count = 0
          ids.uniq.sort.each do |id|
            pm = ProjectMedia.find_by_id(id)
            next if pm.nil? || !pm.cluster_id.nil?
            media_type = {
              'UploadedVideo' => 'video',
              'UploadedAudio' => 'audio',
              'UploadedImage' => 'image',
              'Claim' => 'text',
              'Link' => 'text'
            }[pm.media.type]
            next if pm.archived == ::CheckArchivedFlags::FlagCodes::TRASHED || !team_ids.include?(pm.team_id) || media_type != type
            cluster_obj ||= Cluster.create!(project_media: pm)
            cluster_obj.project_medias << pm
            count += 1
          end
          if cluster_obj.nil?
            log "No cluster created, since we have #{count} items"
          else
            log "Updated #{count} items for cluster ID #{cluster_obj.id}"
          end
        end
        FileUtils.rm(key)
      end

      # Now handle manually-added items
      log "-----------------------------------\nComputing cluster for manually-added relationships\n-----------------------------------"
      join = 'INNER JOIN relationships r ON r.target_id = project_medias.id'
      relationship_condition = ['((r.relationship_type = ? AND r.user_id != ?) OR (r.confirmed_by IS NOT NULL))', Relationship.confirmed_type.to_yaml, BotUser.alegre_user.id]
      ProjectMedia.joins(join).where(team_id: team_ids).where(*relationship_condition).find_each do |pm|
        main = Relationship.confirmed_parent(pm)
        cluster = pm.cluster
        if main != pm && (cluster.nil? || (cluster.size == 1 && cluster.project_media_id == pm.id)) && (main.cluster_id && main.cluster_id != pm.cluster_id)
          log "Adding item #{pm.id} to cluster #{main.cluster_id}"
          cluster.destroy! unless cluster.nil?
          main.cluster.project_medias << pm
        end
      end
    end
  end
end
