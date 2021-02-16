class AddMappingForNewColumns3 < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          status_index: { type: 'long' },
          type_of_media: { type: 'long' }
        }
      }
    }
    client.indices.put_mapping options
    total = ProjectMedia.count
    i = 0
    ProjectMedia.select(:id).find_in_batches(batch_size: 3000) do |pms|
      i += 1
      puts "#{i * 3000} / #{total}"
      p = { status_index: 0, type_of_media: 0 }
      body = {
        script: { source: "ctx._source.status_index = params.status_index ; ctx._source.type_of_media = params.type_of_media", params: p },
        query: { terms: { annotated_id: pms.map(&:id) } }
      }
      options[:body] = body
      client.update_by_query options
    end
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
