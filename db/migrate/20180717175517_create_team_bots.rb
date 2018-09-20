class CreateTeamBots < ActiveRecord::Migration
  def change
    create_table :team_bots do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :description
      t.string :file
      t.string :request_url, null: false
      t.string :role, null: false, default: 'editor'
      t.string :version, default: '0.0.1'
      t.string :source_code_url
      t.integer :bot_user_id
      t.integer :team_author_id
      t.text :events
      t.boolean :approved, default: false
      t.boolean :limited, default: false
      t.datetime :last_called_at
      t.timestamps null: false
    end

    create_table :team_bot_installations do |t|
      t.references :team
      t.references :team_bot
      t.timestamps null: false
    end
  end
end
