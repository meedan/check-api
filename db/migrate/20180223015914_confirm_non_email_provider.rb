class ConfirmNonEmailProvider < ActiveRecord::Migration
  def change
  	User.where.not(provider: "").find_each do |u|
  		u.confirm
  	end
  end
end
