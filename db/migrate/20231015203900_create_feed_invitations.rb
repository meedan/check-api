class CreateFeedInvitations < ActiveRecord::Migration[6.1]
  def change
    create_table :feed_invitations do |t|
      t.string :email, null: false
      t.integer :state, null: false, default: 0
      t.references :feed, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false # User who invited

      t.timestamps
    end
    add_index :feed_invitations, [:email, :feed_id], unique: true
  end
end
