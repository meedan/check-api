class AddLockedToAnnotations < ActiveRecord::Migration
  def change
  	add_column :annotations, :locked, :boolean, default: false
  end
end
