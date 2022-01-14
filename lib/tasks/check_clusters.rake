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

      # Reset the cluster_id and cluster_center columns of existing items
      print 'Resetting all cluster IDs to null and cluster centers to false...'
      ids_to_reset = ProjectMedia.where.not(cluster_id: nil).map(&:id).concat(ProjectMedia.where(cluster_center: true).map(&:id)).uniq
      ProjectMedia.where(id: ids_to_reset).update_all(cluster_id: nil, cluster_center: false)
      # Reset cluster_id and cluster_center in ElasticSearch as well
      es_body = []
      ids_to_reset.each do |id|
        es_body << {
          update: {
            _index: ::CheckElasticSearchModel.get_index_alias,
            _id: Base64.encode64("ProjectMedia/#{id}"),
            retry_on_conflict: 3,
            data: { doc: { cluster_id: nil, cluster_center: 0 } }
          }
        }
      end
      $repository.client.bulk(body: es_body) unless es_body.empty?
      puts 'Done.'

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
        response['clusters'].each_with_index do |cluster, cluster_id|
          ids = []
          cluster.each do |node|
            id = node.dig('context', 0, 'project_media_id') unless node['context'].blank?
            unless id
              id = begin Base64.decode64(node['data_type_id']).match(/^check-project_media-([0-9]+)-.*$/)[1].to_i rescue 0 end
            end
            ids << id
          end
          ids_to_update = []
          ids.uniq.sort.each do |id|
            pm = ProjectMedia.find_by_id(id)
            next if pm.nil?
            media_type = {
              'UploadedVideo' => 'video',
              'UploadedAudio' => 'audio',
              'UploadedImage' => 'image',
              'Claim' => 'text',
              'Link' => 'text'
            }[pm.media.type]
            next if pm.nil? || pm.archived == ::CheckArchivedFlags::FlagCodes::TRASHED || !team_ids.include?(pm.team_id) || media_type != type
            ids_to_update << id
          end
          next if ids_to_update.empty?
          ProjectMedia.where(id: ids_to_update).update_all(cluster_id: cluster_id)
          first = ProjectMedia.find(ids_to_update.first)
          first.cluster_center = true
          first.save!

          # Update cluster_id in ElasticSearch as well
          es_body = []
          ids_to_update.each do |id|
            es_body << {
              update: {
                _index: ::CheckElasticSearchModel.get_index_alias,
                _id: Base64.encode64("ProjectMedia/#{id}"),
                retry_on_conflict: 3,
                data: { doc: { cluster_id: cluster_id } }
              }
            }
          end
          $repository.client.bulk body: es_body

          log "Updated #{ids_to_update.size} items for cluster ID #{cluster_id}"
        end
        FileUtils.rm(key)
      end
    end
  end
end
