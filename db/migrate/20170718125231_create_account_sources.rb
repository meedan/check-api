class CreateAccountSources < ActiveRecord::Migration
  def change
    create_table :account_sources do |t|
      t.belongs_to :account, index: true
      t.belongs_to :source, index: true
      t.timestamps null: false
    end
  end
end
