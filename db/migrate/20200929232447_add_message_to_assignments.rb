class AddMessageToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :message, :text
  end
end
