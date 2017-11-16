class AddAttributionToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :attribution, :text
  end
end
