class CreateLoginActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :login_activities do |t|
      t.string :scope
      t.string :strategy
      t.string :identity
      t.boolean :success
      t.string :failure_reason
      t.references :user, polymorphic: true
      t.string :context
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.datetime :created_at
    end

    add_index :login_activities, :identity
    add_index :login_activities, :ip
  end
end
