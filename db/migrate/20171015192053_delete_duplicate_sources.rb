class DeleteDuplicateSources < ActiveRecord::Migration
  def change
    Source.where.not(team_id: nil, id: ProjectSource.all.map(&:source_id)).destroy_all
  end
end
