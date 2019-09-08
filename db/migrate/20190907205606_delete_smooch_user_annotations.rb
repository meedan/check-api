class DeleteSmoochUserAnnotations < ActiveRecord::Migration
  def change
    Dynamic.where(annotation_type: 'smooch_user').destroy_all
  end
end
