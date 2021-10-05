class RemoveFullTagIndex < ActiveRecord::Migration[4.2]
  def change
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
