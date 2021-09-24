class AddConfirmableToDevise < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_index :users, :confirmation_token, unique: true
    User.all.each do |u|
      u.confirm
      u.save!
    end
  end

  def down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
  end
end
