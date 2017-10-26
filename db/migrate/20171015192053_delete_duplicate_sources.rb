class DeleteDuplicateSources < ActiveRecord::Migration
  def change
  	ids = ProjectSource.all.map(&:source_id)
  	ids.concat User.all.map(&:source_id)
  	Source.where.not(team_id: nil, id: ids).destroy_all
  end
end
