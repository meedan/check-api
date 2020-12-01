class AddMappingForNewColumns < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          report_status: { type: 'long' },
          tags_as_sentence: { type: 'long' },
          media_published_at: { type: 'long' }
        }
      }
    }
    client.indices.put_mapping options
    total = ProjectMedia.count
    i = 0
    ProjectMedia.select(:id).find_in_batches(batch_size: 3000) do |pms|
      i += 1
      puts "#{i * 3000} / #{total}"
      p = { report_status: 0, tags_as_sentence: 0, media_published_at: 0 }
      body = {
        script: { source: "ctx._source.report_status=params.report_status;ctx._source.tags_as_sentence=params.tags_as_sentence;ctx._source.media_published_at = params.media_published_at", params: p },
        query: { terms: { annotated_id: pms.map(&:id) } }
      }
      options[:body] = body
      client.update_by_query options
    end
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
