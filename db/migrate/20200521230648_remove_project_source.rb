class RemoveProjectSource < ActiveRecord::Migration
  def change
  	 Rails.cache.write('check:migrate:remove_project_source', ProjectSource.last&.id)
  end
end
