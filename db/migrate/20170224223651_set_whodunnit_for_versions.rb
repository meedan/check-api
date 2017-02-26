class SetWhodunnitForVersions < ActiveRecord::Migration
  def change
    add_column(:versions, :object_after, :text) unless PaperTrail::Version.column_names.include?('object_after')

    PaperTrail::Version.find_each do |version|
      print "Changing version #{version.id}... "

      if version.object_after.blank?
        print 'Setting object after changes... '
        version.object_after = self.apply_changes(version)
      end

      if version.whodunnit.blank?
        object = JSON.parse(version.object_after)
        author = object['annotator_id'] || object['user_id']
        version.whodunnit = author.to_s
      end

      version.save!
      puts version.reload.object_after
      
      puts "Saved version #{version.id}"
    end
  end

  def deserialize_change(d)
    ret = d
    unless d.nil?
      begin
        ret = YAML.load(d)
      rescue StandardError
        ret = eval(d)
      end
    end
    ret
  end

  def apply_changes(version)
    object = version.get_object
    changes = JSON.parse(version.object_changes)

    { 'is_annotation?' => 'data', Team => 'settings', DynamicAnnotation::Field => 'value' }.each do |condition, key|
      obj = version.item_class.new
      matches = condition.is_a?(String) ? obj.send(condition) : obj.is_a?(condition)
      if matches
        object[key] = self.deserialize_change(object[key]) if object[key]
        changes[key].collect!{ |change| self.deserialize_change(change) unless change.nil? } if changes[key]
      end
    end
    
    changes.each do |key, pair|
      object[key] = pair[1]
    end
    object.to_json
  end
end
