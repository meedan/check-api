class MigrateDuplicateSourcesPerTeam < ActiveRecord::Migration
  def change
  	Source.select('lower(name) as lname', :team_id).where.not(team_id: nil).group(['lname', 'team_id']).having('count(*) > 1').each do |item|
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
