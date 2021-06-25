class ConfirmNonEmailProvider < ActiveRecord::Migration[4.2]
  def change
  	User.where.not(provider: "").find_each do |u|
  		u.confirm
  	end
  end
end
