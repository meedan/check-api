class AddFileToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :file, :string
  end
end
