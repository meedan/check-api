class AddMappingForAssignmentSearch < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          assigned_user_ids: { type: 'long' }
        }
      }
    }
    client.indices.put_mapping options
    pmids = []
    total = Assignment.where(assigned_type: ['Annotation', 'Dynamic']).count
    i = 0
    Assignment.where(assigned_type: ['Annotation', 'Dynamic']).find_in_batches(batch_size: 2500) do |as|
      i += 1
      puts "#{i * 2500} / #{total}"
      as.each do |a|
        if a.assigned && a.assigned.annotation_type == 'verification_status'
          pmids << a.assigned.annotated_id.to_i unless pmids.include?(a.assigned.annotated_id.to_i)
        end
      end
    end
    body = {
      script: { source: "ctx._source.assigned_user_ids = params.assigned_user_ids", params: { assigned_user_ids: [] } },
      query: { terms: { annotated_id: pmids } }
    }
    options[:body] = body
    client.update_by_query options
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
