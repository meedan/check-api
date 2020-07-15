class ProjectMediaProject < ActiveRecord::Base
  attr_accessor :previous_project_id, :set_tasks_responses

  include CheckElasticSearch
  include CheckPusher
  include ValidationsHelper

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }, class_name: 'Version'

  belongs_to :project
  belongs_to :project_media

  validates_presence_of :project, :project_media
  validate :project_is_not_archived, unless: proc { |pmp| pmp.is_being_copied  }

  after_destroy :update_index_in_elasticsearch
  after_commit :update_index_in_elasticsearch, :add_remove_team_tasks, on: [:create, :update]

  notifies_pusher on: [:save, :destroy],
                  event: 'media_updated',
                  targets: proc { |pmp| [pmp.project, pmp.project.team] },
                  bulk_targets: proc { |pmp| [pmp.team] },
                  data: proc { |pmp| { id: pmp.id }.to_json }

  def check_search_team
    team = self.team
    team.check_search_team
  end

  def check_search_trash
    team = self.team
    team.check_search_trash
  end

  def check_search_project(project = nil)
    project ||= self.project
    return nil if project.nil?
    project.check_search_project
  end

  def check_search_project_was
    self.check_search_project(self.project_was)
  end


  def project_was
    Project.find_by_id(self.previous_project_id) unless self.previous_project_id.blank?
  end

  def graphql_deleted_id
    self.project_media.graphql_id
  end

  def team
    self.project&.team
  end

  def is_being_copied
    self.team && self.team.is_being_copied
  end

  private

  def project_is_not_archived
    parent_is_not_archived(self.project, I18n.t(:error_project_archived)) unless self.project.nil?
  end

  def add_remove_team_tasks
    existing_items = ProjectMediaProject.where(project_media_id: self.project_media_id).count
    options = {
      model: self.project_media,
      only_selected: existing_items > 1,
      set_tasks_responses: self.set_tasks_responses
    }
    TeamTaskWorker.perform_in(1.second, 'add_or_move', self.project_id, YAML::dump(User.current), YAML::dump(options))
  end

  def update_index_in_elasticsearch
    return if self.disable_es_callbacks
    self.update_elasticsearch_doc(['project_id'], { 'project_id' => self.project_media.projects.map(&:id) }, self.project_media)
  end
end
