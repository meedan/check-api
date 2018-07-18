class RemoveFullTagIndex < ActiveRecord::Migration
  def change
  	client = MediaSearch.gateway.client
    options = {
      index: CheckElasticSearchModel.get_index_name,
      type: 'tag_search',
      body: {
        script: { inline: "ctx._source.remove('full_tag')" },
        query: { bool: { must: [ { exists: { field: "full_tag" } } ] } }
      }
    }
    client.update_by_query options
    sleep 5
  	CheckElasticSearchModel.reindex_es_data
    sleep 5
    # Remove full_tag field and trim spaces
    Annotation.where(annotation_type: 'tag').find_each do |t|
      t = t.load
      data = t.data
      data.delete(:full_tag)
      trim_tag = data[:tag].strip!
      if trim_tag.nil?
        # just update columns
        t.update_columns(data: data)
      else
        # re-save tag to update ES
        t.data = data
        t.save(validate: false)
        # fix versions (remove full_tag and strip tag value)
        v = t.versions.last
        object_after = JSON.parse(v.object_after)
        object_after["data"].delete("full_tag")
        object_after["data"]["tag"].strip!
        v.object_after = object_after.to_json
        v.save!
      end
    end
  end
end
