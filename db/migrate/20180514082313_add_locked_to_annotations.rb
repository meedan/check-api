class AddLockedToAnnotations < ActiveRecord::Migration[4.2]
  def change
  	add_column :annotations, :locked, :boolean, default: false
  end
end
