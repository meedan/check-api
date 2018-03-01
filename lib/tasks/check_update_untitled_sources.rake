
def update_source_name(s)
	a = s.accounts.first
	s.name = "Untitled-#{s.created_at.strftime('%Y%m%d%H%M%S%L')}"
	unless a.nil?
		data = a.data
		s.update_from_pender_data(data) unless data['author_name'].blank?
	end
	s.save!
end

namespace :check do
  desc "Fix untitled sources"
  task fix_untitled_sources: :environment do
  	sources = []
  	Source.where(name: 'Untitled').find_each do |s|
  		sources << s.id
  		medias = s.medias
  		if s.team.nil? || medias.count == 0
  			update_source_name(s)
  		else
  			Team.current = s.team
	  		medias.each do |pm|
	  			a = pm.media.account
	  			if a.embed['author_name'].blank?
	  				pm.refresh_media= true
	  			else
	  				AccountSource.where(source_id: s.id, account_id: a.id).destroy_all
	  				source = Account.create_for_source(a.url, nil).source
	  				unless source.nil?
				      unless ProjectSource.where(project_id: pm.project_id, source_id: source.id).exists?
				        ps = ProjectSource.new
				        ps.project_id = pm.project_id
				        ps.source_id = source.id
				        ps.skip_check_ability = true
				        ps.save!
				      end
				    end
	  			end
	  		end
	  		update_source_name(s)
  		end
	  	print '.'
  	end
  	puts "#{sources.count} were updated with ids #{sources}"
  end
 end