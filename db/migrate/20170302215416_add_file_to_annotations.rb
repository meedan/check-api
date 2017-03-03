class AddFileToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :file, :string
  end
end
