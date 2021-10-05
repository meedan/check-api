class RemoveContextFromAnnotations < ActiveRecord::Migration[4.2]
  def change
    remove_columns :annotations, :context_id, :context_type
  end
end
