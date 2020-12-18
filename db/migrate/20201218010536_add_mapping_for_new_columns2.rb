class AddMappingForNewColumns2 < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          comment_count: { type: 'long' },
          reaction_count: { type: 'long' },
          related_count: { type: 'long' },
          suggestions_count: { type: 'long' }
        }
      }
    }
    client.indices.put_mapping options
    total = ProjectMedia.count
    i = 0
    ProjectMedia.select(:id).find_in_batches(batch_size: 3000) do |pms|
      i += 1
      puts "#{i * 3000} / #{total}"
      p = { comment_count: 0, reaction_count: 0 }
      body = {
        script: { source: "ctx._source.comment_count = params.comment_count ; ctx._source.reaction_count = params.reaction_count ; ctx._source.related_count = params.related_count ; ctx._source.suggestions_count = params.suggestions_count", params: p },
        query: { terms: { annotated_id: pms.map(&:id) } }
      }
      options[:body] = body
      client.update_by_query options
    end
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
