class AddDefaultToBots < ActiveRecord::Migration
  def change
    add_column :users, :default, :boolean, default: false
    tb = BotUser.where(login: 'alegre').last
    tb.default = true
    tb.save!
  end
end
