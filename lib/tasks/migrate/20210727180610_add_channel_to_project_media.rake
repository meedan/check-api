namespace :check do
  namespace :migrate do
    task set_elastic_seach_channel: :environment do
      started = Time.now.to_i
      client = $repository.client
      options = { index: CheckElasticSearchModel.get_index_alias }
      fetch = User.where(login: 'fetch').last
      smooch = User.where(login: 'smooch').last
      all_channels = CheckChannels::ChannelCodes.all_channels
      Team.find_each do |team|
        print '.'
        # Set channel = MANUAL for all team items
        body = {
          script: {
            source: "ctx._source.channel = params.channel", params: { channel: CheckChannels::ChannelCodes::MANUAL }
          },
          query: { term: { team_id: team.id } }
        }
        options[:body] = body
        # client.update_by_query options
        # set channel for fetch items
        unless fetch.nil?
          print '.'
          fetch_pms = fetch.project_medias.where(team_id: team.id).map(&:id)
          # update PG
          ProjectMedia.where(id: fetch_pms).update_all(channel: CheckChannels::ChannelCodes::FETCH)
          body = {
            script: {
              source: "ctx._source.channel = params.channel", params: { channel: CheckChannels::ChannelCodes::FETCH }
            },
            query: { terms: { annotated_id: fetch_pms } }
          }
          options[:body] = body
        end
        # set channel for smooch items
        unless smooch.nil?
          smooch.project_medias.where(team_id: team.id).find_in_batches(:batch_size => 2500) do |pms|
            channel_mapping = Hash.new {|hash, key| hash[key] = [] }
            ids = pms.map(&:id)
            DynamicAnnotation::Field.select('dynamic_annotation_fields.id, value_json, a.annotated_id as pm_id').where(
              field_name: 'smooch_data', annotation_type: 'smooch')
            .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id AND a.annotated_type = 'ProjectMedia'")
            .where('a.annotated_id IN (?)', ids).find_each do |df|
              print '.'
              channel = df.value_json.dig('source', 'type')&.upcase              
              channel_mapping[channel] << df.pm_id unless channel.blank?
            end
            channel_mapping.each do |k, pm_ids|
              channel_value = all_channels.keys.include?(k) ? all_channels[k] : nil
              unless channel_value.blank?
                # update PG
                ProjectMedia.where(id: pm_ids).update_all(channel: channel_value) 
                # Update ES
                body = {
                  script: {
                    source: "ctx._source.channel = params.channel", params: { channel: channel_value }
                  },
                  query: { terms: { annotated_id: pm_ids } }
                }
                options[:body] = body
              end
            end
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end