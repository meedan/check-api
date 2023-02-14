class DeviseCreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :name, null: false, default: ''
      t.string :login, null: false, default: ''
      
      t.string :token, null: false, default: ''
      t.boolean :default, default: false

      ## Database authenticatable
      t.string :email
      t.string :encrypted_password, null: true, default: ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## Invitable
      t.string :invitation_token
      t.string :raw_invitation_token
      t.datetime :invitation_created_at
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.integer :invitation_limit
      t.integer :invited_by_id
      t.string :invited_by_type

      t.datetime :last_accepted_terms_at
      t.string :image
      t.string :type, default: nil
      t.integer :source_id, index: true
      t.boolean :is_active, default: true
      t.boolean :is_admin, default: false
      t.integer :current_project_id, :integer
      t.text :settings
      t.datetime :last_active_at
      t.text :cached_teams
      t.integer :current_team_id
      t.boolean :completed_signup, default: true
      t.integer :api_key_id
      t.string :unconfirmed_email

      t.timestamps null: false
    end

    add_index :users, :reset_password_token, unique: true
    add_index :users, :token, unique: true
    add_index :users, :invitation_token, :unique => true
    add_index :users, :email
    add_index :users, :type
    add_index :users, :login
  end
end
