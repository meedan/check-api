class AddCompletedSignUpToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :completed_signup, :boolean, default: true
  end
end
