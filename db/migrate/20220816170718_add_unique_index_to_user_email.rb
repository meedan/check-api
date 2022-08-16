class AddUniqueIndexToUserEmail < ActiveRecord::Migration[5.2]
  def change
    # remove duplicate emails
    query = "SELECT email, COUNT(id) FROM users WHERE email IS NOT NULL AND email != '' group by email HAVING COUNT(id) > 1"
    emails = ApplicationRecord.connection.execute(query).to_a.collect{|u| u['email']}
    emails.delete_if{ |e| e.blank? }
    User.where(email: emails).where('last_active_at IS NULL').destroy_all
    # add uniq index
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, unique: true, where: "email IS NOT NULL AND email != ''"
  end
end
