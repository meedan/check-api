class AddCompletedSignUpToUsers < ActiveRecord::Migration
  def change
    add_column :users, :completed_signup, :boolean, default: true
  end
end
