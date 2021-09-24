class AddAttributionToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :attribution, :text
  end
end
