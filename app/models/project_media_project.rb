class ProjectMediaProject < ActiveRecord::Base
  include CheckElasticSearch

  belongs_to :project
  belongs_to :project_media

  after_create :update_index_in_elasticsearch
  after_destroy :update_index_in_elasticsearch

  private

  def update_index_in_elasticsearch
    return if self.disable_es_callbacks
    self.update_elasticsearch_doc(['project_id'], { 'project_id' => self.project_media.project_media_projects.map(&:project_id) }, self.project_media)
  end
end
