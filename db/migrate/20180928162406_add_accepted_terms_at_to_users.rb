class AddAcceptedTermsAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_accepted_terms_at, :datetime
  end
end
