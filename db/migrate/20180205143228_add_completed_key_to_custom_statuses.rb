class AddCompletedKeyToCustomStatuses < ActiveRecord::Migration
  def change
  	Team.find_each do |t|
  		if t.get_limits_custom_statuses
  			t.settings[:media_verification_statuses][:statuses].each {|s| s[:completed] = ''}
  			t.save!
  		end
  	end
  end
end
