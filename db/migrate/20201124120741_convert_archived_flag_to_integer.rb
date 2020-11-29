class ConvertArchivedFlagToInteger < ActiveRecord::Migration
  def change
    # Team
    if Team.column_for_attribute('archived').type != :integer
      change_column :teams, :archived, :boolean, default: nil
      change_column :teams, :archived, :integer, using: 'archived::integer', default: 0
    end
    # Project
    if Project.column_for_attribute('archived').type != :integer
      change_column :projects, :archived, :boolean, default: nil
      change_column :projects, :archived, :integer, using: 'archived::integer', default: 0
    end
    # ProjectMedia
    if ProjectMedia.column_for_attribute('archived').type != :integer
      change_column :project_medias, :archived, :boolean, default: nil
      change_column :project_medias, :archived, :integer, using: 'archived::integer', default: 0
    end
    # Source
    if Source.column_for_attribute('archived').type != :integer
      change_column :sources, :archived, :boolean, default: nil
      change_column :sources, :archived, :integer, using: 'archived::integer', default: 0
    end
  end
end
