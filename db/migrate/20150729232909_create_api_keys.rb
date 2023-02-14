class CreateApiKeys < ActiveRecord::Migration[4.2]
  def change
    create_table :api_keys do |t|
      t.string :access_token, null: false, default: ''
      t.datetime :expire_at
      t.jsonb :rate_limits, default: {}
      t.string :application
      t.timestamps
    end
  end
end
