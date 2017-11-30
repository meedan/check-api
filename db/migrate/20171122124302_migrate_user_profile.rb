class MigrateUserProfile < ActiveRecord::Migration
  def change
  	User.find_each do |u|
  		s = u.source
  		unless s.nil?
  			si = SourceIdentity.new
  			si.name = u.read_attribute(:name)
  			si.bio = s.read_attribute(:slogan)
  			si.file = s.read_attribute(:avatar)
  			si.annotated = s
		    si.annotator = u
		    si.skip_check_ability = true
		    si.skip_notifications = true
		    si.save!
  		end
  	end
  end
end
