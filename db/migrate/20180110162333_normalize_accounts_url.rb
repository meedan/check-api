class NormalizeAccountsUrl < ActiveRecord::Migration
  def change
  	Account.find_each do |a|
  		url = a.url
  		a.validate_pender_result
  		if a.url != url
  			existing = Account.where(url: a.url).last
  			if existing.nil?
  				a.disable_es_callbacks = true
  				a.save!
  			else
  				Media.where(account_id: a.id).update_all(account_id: existing.id)
  				AccountSource.where(account_id: a.id).update_all(account_id: existing.id)
  				a.destroy
  			end
  		end
  	end
  end
end
