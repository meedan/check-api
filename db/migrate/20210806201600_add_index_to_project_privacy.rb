class AddIndexToProjectPrivacy < ActiveRecord::Migration
  def change
    add_index :projects, :privacy
  end
end
