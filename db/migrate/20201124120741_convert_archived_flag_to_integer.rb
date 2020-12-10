class ConvertArchivedFlagToInteger < ActiveRecord::Migration
  def change
    { teams: Team, projects: Project, project_medias: ProjectMedia, sources: Source }.each do |table, model|
      column = model.column_for_attribute('archived')
      unless column.nil? || column.type == :integer
        change_column table, :archived, :boolean, default: nil
        change_column table, :archived, :integer, using: 'archived::integer', default: 0
      end
    end
  end
end
