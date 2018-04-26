
def update_source_name(s)
	a = s.accounts.first
	s.name = "Untitled-#{s.created_at.strftime('%Y%m%d%H%M%S%L')}"
	unless a.nil?
		data = a.data
		s.update_from_pender_data(data) unless data['author_name'].blank?
	end
	s.save!
end

def parse_conditions(args)
	condition = {}
	return condition if args.blank?
	args.each do |a|
  	arg = a.split('&')
  	arg.each do |pair|
    	key, value = pair.split(':')
    	condition.merge!({ key => value })
  	end
  end
  condition
end

namespace :check do
	# bundle exec rake check:fix_untitled_sources['id:1&name:sname']
	# bundle exec rake check:fix_untitled_sources to fix sources with name == 'Untitled'
  desc "Fix untitled sources"
  task fix_untitled_sources: :environment do |t, args|
  	condition = parse_conditions args.extras
  	condition = {'name' => 'Untitled'} if condition.blank?
  	sources = []
  	Source.where(condition).find_each do |s|
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

  # bundle exec rake check:fix_duplicate_source_per_team['team_id:1'] to fix duplication on specific team
	# bundle exec rake check:fix_duplicate_source_per_team to fix duplication on all teams
  desc "Fix duplicate sources per team"
  task fix_duplicate_source_per_team: :environment do |t, args|
  	condition = parse_conditions args.extras
  	Source.select('lower(name) as lname', :team_id).where(condition).where.not(team_id: nil).group(['lname', 'team_id']).having('count(*) > 1').each do |item|
  		sources = Source.where('lower(name) = ? AND team_id = ?', item['lname'], item['team_id']).to_a
  		s = sources.shift
  		ids = sources.map(&:id)
			User.where(source_id: ids).update_all(source_id: s.id)
			AccountSource.where(source_id: ids).update_all(source_id: s.id)
			ProjectSource.where(source_id: ids).update_all(source_id: s.id)
			ClaimSource.where(source_id: ids).update_all(source_id: s.id)
			# Update annotations
			Annotation.where(annotated_type: 'Source', annotated_id: ids).update_all(annotated_id: s.id)
			# Destroy duplicate sources
			Source.where(id: ids).destroy_all
  	end
  end

 end