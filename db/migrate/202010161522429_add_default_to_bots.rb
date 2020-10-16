class AddDefaultToBots < ActiveRecord::Migration
  def change
    add_column :users, :default, :boolean, default: false
  end
end
