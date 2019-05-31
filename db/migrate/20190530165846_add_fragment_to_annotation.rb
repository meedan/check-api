class AddFragmentToAnnotation < ActiveRecord::Migration
  def change
    add_column :annotations, :fragment, :text
  end
end
