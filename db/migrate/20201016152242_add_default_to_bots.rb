class AddDefaultToBots < ActiveRecord::Migration
  def change
    add_column(:users, :default, :boolean, default: false) unless column_exists?(:users, :default)
    unless Rails.env.test?
      User.reset_column_information
      BotUser.where(login: 'alegre').update_all(default: true)
    end
  end
end
