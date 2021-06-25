class UpdateUserAccount < ActiveRecord::Migration[4.2]
  def change
    User.where(provider: 'slack').find_each do |u|
      account = u.account
      unless account.nil?
        account.created_on_registration = true
        account.refresh_embed_data
      end
    end
  end
end
