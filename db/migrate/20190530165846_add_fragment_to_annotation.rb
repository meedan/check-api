class AddFragmentToAnnotation < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :fragment, :text
  end
end
