class AddSmoochAnnotationsIndex < ActiveRecord::Migration
  def change
    ids = Dynamic.where(annotation_type: 'smooch').map(&:id)
    unless ids.blank?
      Dynamic.where(id: ids).find_each do |d|
        d.send(:add_elasticsearch_dynamic)
      end
    end
  end
end
