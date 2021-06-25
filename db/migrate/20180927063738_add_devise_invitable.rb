class AddDeviseInvitable < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :invitation_token, :string
    add_column :users, :raw_invitation_token, :string
    add_column :users, :invitation_created_at, :datetime
    add_column :users, :invitation_sent_at, :datetime
    add_column :users, :invitation_accepted_at, :datetime
    add_column :users, :invitation_limit, :integer
    add_column :users, :invited_by_id, :integer
    add_column :users, :invited_by_type, :string
    add_index :users, :invitation_token, :unique => true
    add_column :team_users, :invited_by_id, :integer
    add_column :team_users, :invitation_token, :string
    add_column :team_users, :raw_invitation_token, :string
    add_column :team_users, :invitation_accepted_at, :datetime
    # Allow null encrypted_password
    change_column_null :users, :encrypted_password, :string, true
  end
end
