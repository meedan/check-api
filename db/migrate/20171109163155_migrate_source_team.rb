class MigrateSourceTeam < ActiveRecord::Migration
  def change
  	migrated_sources = []
  	Source.where.not(team_id: nil).find_each do |s|
  		next if migrated_sources.include?(s.id)
  		create_team_source(s.id, s, s.user)
  		# create si annotation
  		create_source_annotation(s, s)
  		# find duplicate sources
  		find_duplicate_sources(s).each do |ds|
  			next unless TeamSource.where(source_id: ds).last.nil?
  			migrated_sources << ds
  			ms = Source.where(id: ds).last
  			unless ms.nil? or ms.team_id.nil?
  				ts = create_team_source(s.id, ms, ms.user)
  				create_source_annotation(ts, ts.source) if s.read_attribute(:name).downcase != ms.read_attribute(:name).downcase
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
    d = Source.where.not(id: s.id).where('lower(name) =  ?', s.read_attribute(:name).downcase).map(&:id)
    d.concat AccountSource.where.not(source_id: s.id).where(account: s.accounts).map(&:source_id)
    d.uniq
  end

  def create_team_source(sid, target, user)
  	ts = TeamSource.find_or_create_by(team_id: target.team_id, source_id: sid)
  	# update annotations count
  	ts.cached_annotations_count = target.project_sources.sum(:cached_annotations_count)
  	ts.user = user if ts.user.nil? && !user.nil?
    ts.archived = ts.team.archived
  	ts.save!
  	migrate_source_annotations(ts, target)
  	ts
  end

  def create_source_annotation(annotated, source)
    si = SourceIdentity.new
    si.name = source.read_attribute(:name)
    si.bio = source.read_attribute(:slogan)
    si.file = source.read_attribute(:avatar)
    si.annotated = annotated
    si.annotator = annotated.user
    si.skip_check_ability = true
    si.skip_notifications = true
    si.save!
  end

  def migrate_source_annotations(target, source)
  	# update source annotations
  	Annotation.where.not(annotation_type: 'source_identity').where(annotated_type: 'Source', annotated_id: source.id).update_all(annotated_type: target.class.name, annotated_id: target.id)
  	# update project source annotations
  	Annotation.where(annotated_type: 'ProjectSource', annotated_id: source.project_sources).update_all(annotated_type: target.class.name, annotated_id: target.id)
  	# update versions
  	PaperTrail::Version.where(associated_type: 'ProjectSource', associated_id: source.project_sources).update_all(associated_type: target.class.name, associated_id: target.id)
  end
end
