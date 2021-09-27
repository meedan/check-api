class AddAcceptedTermsAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_accepted_terms_at, :datetime
  end
end
