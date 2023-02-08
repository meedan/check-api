class CreateTeamUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :team_users do |t|
      t.belongs_to :team
      t.belongs_to :user
      t.string :type, index: true
      t.integer :invited_by_id
      t.string :invitation_token
      t.string :raw_invitation_token
      t.datetime :invitation_accepted_at
      t.string :file
      t.text :settings
      t.string :role
      t.string :status, default: "member"
      t.string :invitation_email
      t.integer :lock_version, default: 0, null: false
      t.timestamps null: false
    end

    add_index :team_users, [:team_id, :user_id], unique: true
    add_index :team_users, [:user_id, :team_id, :status]
  end
end
