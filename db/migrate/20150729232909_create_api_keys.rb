class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.string :access_token, null: false, default: ''
      t.datetime :expire_at
      t.timestamps
    end
  end
end
