class DeleteSmoochUserAnnotations < ActiveRecord::Migration[4.2]
  def change
    Dynamic.where(annotation_type: 'smooch_user').destroy_all
  end
end
