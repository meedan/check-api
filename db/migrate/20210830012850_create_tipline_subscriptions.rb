class CreateTiplineSubscriptions < ActiveRecord::Migration
  def change
    create_table :tipline_subscriptions do |t|
      t.string :uid
      t.string :language
      t.references :team
    end
    add_index :tipline_subscriptions, [:uid, :language, :team_id], unique: true
    add_index :tipline_subscriptions, [:language, :team_id]
    add_index :tipline_subscriptions, :uid
    add_index :tipline_subscriptions, :language
    add_index :tipline_subscriptions, :team_id
  end
end
