class ReindexLinksPublishedAt < ActiveRecord::Migration[4.2]
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
          properties: {
            published_at: {
              type: 'date',
            }
          }
      }
    }
    client.indices.put_mapping options
    ProjectMedia.joins(:media).where('medias.type' => 'Link').find_in_batches(:batch_size => 2500) do |pms|
      print '.'
      ids = pms.map(&:id)
      body = {
        script: { source: "ctx._source.published_at = params.published_at", params: { published_at: nil } },
        query: { terms: { annotated_id: ids } }
      }
      options[:body] = body
      client.update_by_query options
    end
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
