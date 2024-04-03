class AddLastReceivedTermsEmailAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_received_terms_email_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
