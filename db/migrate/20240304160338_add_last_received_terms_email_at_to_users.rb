class AddLastReceivedTermsEmailAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_received_terms_email_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
    User.find_each do |u|
      u.update_columns(last_received_terms_email_at: u.last_accepted_terms_at)
    end
  end
end
