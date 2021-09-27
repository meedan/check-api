class AddIndexToProjectPrivacy < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :privacy
  end
end
