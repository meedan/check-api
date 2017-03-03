class RemoveContextFromAnnotations < ActiveRecord::Migration
  def change
    remove_columns :annotations, :context_id, :context_type
  end
end
