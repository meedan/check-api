class AddDefaultToBots < ActiveRecord::Migration
  def change
    add_column(:users, :default, :boolean, default: false) unless column_exists?(:users, :default)
    tb = BotUser.where(login: 'alegre').last
    tb.default = true
    tb.save!
  end
end
