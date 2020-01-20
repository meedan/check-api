class ProjectMediaProject < ActiveRecord::Base
  include CheckElasticSearch
  include CheckNotifications::Pusher

  belongs_to :project
  belongs_to :project_media

  after_create :update_index_in_elasticsearch, :set_project_media_project_id
  after_destroy :update_index_in_elasticsearch, :unset_project_media_project_id

  notifies_pusher on: :commit, event: 'media_updated', targets: proc { |pmp| [pmp.project, pmp.project.team] }, data: proc { |pmp| { id: pmp.id }.to_json }

  def check_search_project
    CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => self.project_id }, 'projects' => [self.project_id] }.to_json)
  end

  def graphql_deleted_id
    self.project_media.graphql_id
  end

  private

  def update_index_in_elasticsearch
    return if self.disable_es_callbacks
    self.update_elasticsearch_doc(['project_id'], { 'project_id' => self.project_media.project_media_projects.map(&:project_id) }, self.project_media)
  end

  def set_project_media_project_id
    self.project_media.update_column(:project_id, self.project_id) unless self.project_media.is_being_copied
  end

  def unset_project_media_project_id
    id = ProjectMediaProject.where(project_media_id: self.project_media_id).last&.project_id
    self.project_media.update_column(:project_id, id) if self.project_media.project_id != id && !self.project_media.is_being_copied && ProjectMediaProject.where(project_media_id: self.project_media_id, project_id: id).last.nil?
  end
end
