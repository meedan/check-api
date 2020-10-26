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

  after_commit :update_index_in_elasticsearch, :add_remove_team_tasks, on: [:create, :update]
  after_destroy :update_index_in_elasticsearch
  after_commit :remove_related_team_tasks, on: :destroy
  after_save :send_pmp_slack_notification

  notifies_pusher on: [:save, :destroy],
                  event: 'media_updated',
                  targets: proc { |pmp| [pmp.project, pmp.project&.team, pmp.project_was] },
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
    @team || self.project&.team
  end

  def team=(team)
    @team = team
  end

  def is_being_copied
    self.team && self.team.is_being_copied
  end

  def self.bulk_create(inputs, team)
    # Filter IDs
    pmids = ProjectMedia.where(id: inputs.collect{ |input| input['project_media_id'] }, team_id: team.id).select(:id).map(&:id)
    pids = Project.where(id: inputs.collect{ |input| input['project_id'] }, team_id: team.id, archived: false).select(:id).map(&:id)
    inserts = []
    inputs.each do |input|
      inserts << input.to_h if pmids.include?(input['project_media_id']) && pids.include?(input['project_id'])
    end

    # Bulk-insert in a single SQL
    result = ProjectMediaProject.import inserts, validate: false, recursive: false, timestamps: true, on_duplicate_key_ignore: true

    # Bulk-update medias count of each project
    Project.bulk_update_medias_count(pids)

    # Other callbacks to run in background
    ProjectMediaProject.delay.run_bulk_save_callbacks(result.ids.map(&:to_i).to_json, User.current&.id)

    # Notify Pusher
    team.notify_pusher_channel

    # Return first (hopefully only, for the Check Web usecase) project and notify
    first_project = Project.find_by_id(pids[0])
    first_project&.notify_pusher_channel

    { team: team, project: first_project }
  end

  def self.run_bulk_save_callbacks(ids_json, user_id)
    current_user = User.current
    User.current = User.find_by_id(user_id.to_i)
    ids = JSON.parse(ids_json)
    ids.each do |id|
      pmp = ProjectMediaProject.find(id)
      [:send_pmp_slack_notification, :update_index_in_elasticsearch, :add_remove_team_tasks].each { |callback| pmp.send(callback) }
    end
    User.current = current_user
  end

  def self.filter_ids_by_team(input_ids, team)
    pids = []
    pmids = []
    ids = []
    pairs = []
    ProjectMediaProject
      .joins(:project, :project_media)
      .where(id: input_ids, 'projects.team_id' => team.id, 'project_medias.team_id' => team.id)
      .select('project_media_projects.id AS id, projects.id AS pid, project_medias.id AS pmid')
      .each do |pmp|
      ids << pmp.id
      pids << pmp.pid
      pmids << pmp.pmid
      pairs << { project_id: pmp.pid, project_media_id: pmp.pmid }
    end
    [ids.uniq, pids.uniq, pmids.uniq, pairs]
  end

  def self.bulk_destroy(input_ids, fields, team)
    # Filter IDs that belong to this team in a single SQL
    ids, pids, pmids, pairs = self.filter_ids_by_team(input_ids, team)
    pm_graphql_ids = pmids.collect{ |pmid| Base64.encode64("ProjectMedia/#{pmid}") }

    # Bulk-delete in a single SQL
    ProjectMediaProject.where(id: ids).delete_all

    # Bulk-update medias count of each project
    Project.bulk_update_medias_count(pids)

    # Other callbacks to run in background
    ProjectMediaProject.delay.run_bulk_destroy_callbacks(pmids.to_json, pairs.to_json)

    project_was = Project.where(id: fields[:previous_project_id], team_id: team.id).last unless fields[:previous_project_id].blank?

    # Notify Pusher
    team.notify_pusher_channel
    project_was&.notify_pusher_channel

    { team: team, project_was: project_was, check_search_project_was: project_was&.check_search_project, ids: pm_graphql_ids }
  end

  def self.run_bulk_destroy_callbacks(pmids_json, pairs_json)
    ids = JSON.parse(pmids_json)
    pairs = JSON.parse(pairs_json)
    ids.each do |id|
      pm = ProjectMedia.find(id)
      pm.update_elasticsearch_doc(['project_id'], { 'project_id' => { method: 'project_ids', klass: 'ProjectMedia', id: pm.id } }, pm)
    end
    pairs.each { |pair| self.remove_related_team_tasks_bg(pair['project_id'], pair['project_media_id']) }
  end

  def self.bulk_update(input_ids, updates, team)
    # For now let's limit to project_id updates
    return {} if updates.keys.map(&:to_s) != ['project_id'] &&
      updates.keys.map(&:to_s).sort != ['previous_project_id', 'project_id']

    project = Project.where(id: updates[:project_id], team_id: team.id).last
    return {} if project.nil?

    # Filter IDs that belong to this team in a single SQL
    ids, pids, pmids, _pairs = self.filter_ids_by_team(input_ids, team)
    pm_graphql_ids = pmids.collect{ |pmid| Base64.encode64("ProjectMedia/#{pmid}") }

    # Bulk-update in a single SQL
    ProjectMediaProject.where(id: ids).update_all(project_id: updates[:project_id])

    # Bulk-update medias count of each project
    Project.bulk_update_medias_count(pids.concat([updates[:project_id]]))

    # Other callbacks to run in background
    ProjectMediaProject.delay.run_bulk_save_callbacks(ids.to_json, User.current&.id)

    project_was = Project.where(id: updates[:previous_project_id], team_id: team.id).last unless updates[:previous_project_id].blank?

    # Notify Pusher
    team.notify_pusher_channel
    project.notify_pusher_channel
    project_was&.notify_pusher_channel

    { team: team, project: project, project_was: project_was, check_search_project_was: project_was&.check_search_project, ids: pm_graphql_ids }
  end

  def slack_channel(event)
    slack_events = self.project.setting(:slack_events)
    slack_events ||= []
    slack_events.map!(&:with_indifferent_access)
    selected_event = slack_events.select{|i| i['event'] == event }.last
    selected_event.blank? ? nil : selected_event['slack_channel']
  end

  def slack_notification_message(event = nil)
    self.project_media.slack_notification_message(event)
  end

  private

  def project_is_not_archived
    parent_is_not_archived(self.project, I18n.t(:error_project_archived)) unless self.project.nil?
  end

  def add_remove_team_tasks
    only_selected = ProjectMediaProject.where(project_media_id: self.project_media_id).count > 1
    project_media = self.project_media
    project_media.set_tasks_responses = self.set_tasks_responses
    project_media.add_destination_team_tasks(self.project, only_selected)
  end

  def remove_related_team_tasks
    TeamTaskWorker.perform_in(1.second, 'remove_from', self.project_id, YAML::dump(User.current), YAML::dump({ project_media_id: self.project_media_id }))
  end

  def self.remove_related_team_tasks_bg(pid, pmid)
    # Get team tasks that assigned to target list (pid)
    tasks = TeamTask.where("project_ids like ?", "% #{pid}\n%")
    # Get tasks with zero answer (should keep completed tasks)
    Task.where('annotations.annotation_type' => 'task', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => pmid)
    .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tasks.map(&:id))
    .joins("LEFT JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
      AND responses.annotated_type = 'Task'
      AND responses.annotated_id = annotations.id"
      )
    .where('responses.id' => nil).find_each do |t|
      t.skip_check_ability = true
      t.destroy
    end
  end

  def update_index_in_elasticsearch
    return if self.disable_es_callbacks
    self.update_elasticsearch_doc(['project_id'], { 'project_id' => { method: 'project_ids', klass: 'ProjectMedia', id: self.project_media_id } }, self.project_media)
  end

  def send_pmp_slack_notification
    self.send_slack_notification('item_added')
  end
end
