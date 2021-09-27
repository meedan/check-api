class AddMessageToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :message, :text
  end
end
