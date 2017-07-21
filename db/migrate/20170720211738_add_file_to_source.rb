class AddFileToSource < ActiveRecord::Migration
  def change
    add_column :sources, :file, :string
  end
end
