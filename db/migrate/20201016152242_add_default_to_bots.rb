class AddDefaultToBots < ActiveRecord::Migration[4.2]
  def change
    add_column(:users, :default, :boolean, default: false) unless column_exists?(:users, :default)
    tb = BotUser.alegre_user
    tb.default = true
    tb.save!
  end
end
