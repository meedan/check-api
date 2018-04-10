class UpdateUserAccount < ActiveRecord::Migration
  def change
    User.where(provider: 'slack').find_each do |u|
      account = u.account
      account.created_on_registration = true
      account.refresh_embed_data
    end
  end
end
