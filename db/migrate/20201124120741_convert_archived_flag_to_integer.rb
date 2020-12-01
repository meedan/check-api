class ConvertArchivedFlagToInteger < ActiveRecord::Migration
  def change
    { teams: Team, projects: Project, project_medias: ProjectMedia, sources: Source }.each do |table, model|
      column = model.column_for_attribute('archived')
      unless column.nil? || column.type == :integer
        change_column table, :archived, :boolean, default: nil
        change_column table, :archived, :integer, using: 'archived::integer', default: 0
      end
    end
    # update archived logs with 0/1 insted of true/false
    PaperTrail::Version.where("object_changes = ?", '{"archived":[true,false]}').update_all(object_changes: "{\"archived\":[1,0]}")
    PaperTrail::Version.where("object_changes = ?", '{"archived":[false,true]}').update_all(object_changes: "{\"archived\":[0,1]}")
  end
end
