class MigrateSourceTeam < ActiveRecord::Migration
  def change
  	migrated_sources = []
  	Source.where.not(team_id: nil).find_each do |s|
  		next if migrated_sources.include?(s.id)
  		create_team_source(s.id, s.team_id, s.user)
  		# create si annotation
  		s.create_source_identity
  		# find duplicate sources
  		find_duplicate_sources(s).each do |ds|
  			next unless TeamSource.where(source_id: ds).last.nil?
  			migrated_sources << ds
  			ms = Source.where(id: ds).last
  			unless ms.nil? or ms.team_id.nil?
  				ts = create_team_source(s.id, ms.team_id, ms.user)
  				create_team_source_annotation(ts) if s.name.downcase != ms.name.downcase
  				# update user, account_source and project_source
  				User.where(source_id: ms.id).update_all(source_id: s.id)
  				AccountSource.where(source_id: ms.id).update_all(source_id: s.id)
  				ProjectSource.where(source_id: ms.id).update_all(source_id: s.id)
  				# destroy duplicate source
  				ms.destroy
  			end
  		end
  	end
  end

  private

  def find_duplicate_sources(s)
    d = Source.where.not(id: s.id).where('lower(name) =  ?', s.name.downcase).map(&:id)
    d.concat AccountSource.where.not(source_id: s.id).where(account: s.accounts).map(&:source_id)
    d.uniq
  end

  def create_team_source(sid, tid, user)
  	ts = TeamSource.find_or_create_by(team_id: tid, source_id: sid)
  	if ts.user.nil? && !user.nil?
  		ts.user = user
  		ts.save!
  	end
  	ts
  end

  def create_team_source_annotation(ts)
  	si = SourceIdentity.new
    si.name = ts.source.name
    si.bio = ts.source.slogan
    # si.file = ts.source.avatar
    si.annotated = ts
    si.annotator = ts.user
    si.skip_check_ability = true
    si.skip_notifications = true
    si.save!
  end
end
