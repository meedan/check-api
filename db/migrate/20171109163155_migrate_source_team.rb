class MigrateSourceTeam < ActiveRecord::Migration
  def change
  	migrated_sources = []
  	Source.where.not(team_id: nil).find_each do |s|
  		next if migrated_sources.include?(s.id)
  		create_team_source(s.id, s.team_id)
  		# create si annotation
  		s.create_source_identity
  		# find duplicate sources
  		s.find_duplicate_sources.each do |ds|
  			migrated_sources << ds
  			ms = Source.where(id: ds).last
  			unless ms.nil?
  				ts = create_team_source(s.id, ms.team_id)
  				create_team_source_annotation(ts) if s.name.downcase != ms.name.downcase
  				# update account_source and project_source
  				AccountSource.where(source_id: ms.id).update_all(source_id: s.id)
  				ProjectSource.where(source_id: ms.id).update_all(source_id: s.id)
  				# destroy duplicate source
  				ms.destroy
  			end
  		end
  	end
  end

  private

  def create_team_source(sid, tid)
  	ts = TeamSource.new
  	ts.team_id = tid
  	ts.source_id = sid
		ts.skip_check_ability = true
		ts.save!
		ts.reload
  end

  def create_team_source_annotation(ts)
  	si = SourceIdentity.new
    si.name = ts.source.name
    si.bio = ts.source.slogan
    # si.file = ts.source.avatar
    si.annotated = ts
    si.skip_check_ability = true
    si.save!
  end
end
