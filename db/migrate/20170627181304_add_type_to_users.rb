class AddTypeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :type, :string, default: nil
  end
end
