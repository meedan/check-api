class CreateAccountSources < ActiveRecord::Migration[4.2]
  def change
    create_table :account_sources do |t|
      t.belongs_to :account
      t.belongs_to :source, index: true
      t.timestamps null: false
    end
    add_index :account_sources, [:account_id, :source_id], unique: true
  end
end
