class CreateTeamUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :team_users do |t|
      t.belongs_to :team, index: true
      t.belongs_to :user, index: true
      t.string :type, index: true
      t.integer :invited_by_id
      t.string :invitation_token
      t.string :raw_invitation_token
      t.datetime :invitation_accepted_at
      t.timestamps null: false
    end
  end
end
