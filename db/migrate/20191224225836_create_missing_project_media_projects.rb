class CreateMissingProjectMediaProjects < ActiveRecord::Migration
  def change
    pairs = []

    ProjectMedia.find_each do |pm|
      pairs << ProjectMediaProject.new(project_id: pm.project_id, project_media_id: pm.id)
    end
    
    ProjectMediaProject.import pairs, recursive: true, validate: false
  end
end
