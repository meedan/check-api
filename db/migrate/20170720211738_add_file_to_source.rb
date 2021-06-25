class AddFileToSource < ActiveRecord::Migration[4.2]
  def change
    add_column :sources, :file, :string
  end
end
