class AddDefaultToBots < ActiveRecord::Migration
  def change
    add_column(:users, :default, :boolean, default: false) unless column_exists?(:users, :default)
    tb = BotUser.alegre_user
    tb.default = true
    tb.save!
  end
end
