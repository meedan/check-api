class AddSmoochAnnotationsIndex < ActiveRecord::Migration
  def change
    Dynamic.where(annotation_type: 'smooch').find_each do |d|
      d.send(:add_elasticsearch_dynamic)
    end
  end
end
